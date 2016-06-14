require 'fileutils'
require 'open-uri'
require 'yaml'

module Lyp::Package
  class << self

    def list(pattern = nil)
      packages = Dir["#{Lyp.packages_dir}/**/package.ly"].map do |path|
        File.dirname(path).gsub("#{Lyp.packages_dir}/", '')
      end

      if pattern
        if (pattern =~ /[@\>\<\=\~]/) && (pattern =~ Lyp::PACKAGE_RE)
          package, version = $1, $2
          req = Gem::Requirement.new(version) rescue nil
          packages.select! do |p|
            p =~ Lyp::PACKAGE_RE
            p_pack, p_ver = $1, $2

            next false unless p_pack == package

            if req && (p_gemver = Gem::Version.new(p_ver) rescue nil)
              req =~ p_gemver
            else
              p_ver == version
            end
          end
        else
          packages.select! do |p|
            p =~ Lyp::PACKAGE_RE
            $1 =~ /#{pattern}/
          end
        end
      end

      packages.sort do |x, y|
        x =~ Lyp::PACKAGE_RE; x_package, x_version = $1, $2
        y =~ Lyp::PACKAGE_RE; y_package, y_version = $1, $2

        x_version = (x_version && Gem::Version.new(x_version) rescue x)
        y_version = (y_version && Gem::Version.new(y_version) rescue y)

        if (x_package == y_package) && (x_version.class == y_version.class)
          x_version <=> y_version
        else
          x <=> y
        end
      end
    end

    def which(pattern = nil)
      list(pattern).map {|p| "#{Lyp.packages_dir}/#{p}" }
    end

    def install(package_specifier, opts = {})
      unless package_specifier =~ Lyp::PACKAGE_RE
        raise "Invalid package specifier #{package_specifier}"
      end
      package, version = $1, $2

      if version =~ /\:/
        info = install_from_local_files(package, version, opts)
      else
        info = install_from_repository(package, version, opts)
      end

      install_package_dependencies(info[:path], opts)

      if File.directory?(File.join(info[:path], 'fonts'))
        install_package_fonts(info[:path], opts)
      end

      unless opts[:silent]
        if info[:local_path]
          puts "\nInstalled #{package}@#{info[:version]} => #{info[:local_path]}\n\n"
        else
          puts "\nInstalled #{package}@#{info[:version]}\n\n"
        end
      end

      if opts[:test]
        FileUtils.cd(info[:path]) do
          run_tests(info[:path])
        end
      end

      # important: return the installed version
      info[:version]
    end

    LOCAL_PACKAGE_WRAPPER =
      "#(set! lyp:current-package-dir \"%s\")\n\\pinclude \"%s\"\n"

    def install_from_local_files(package, version, opts)
      version =~ /^([^\:]+)\:(.+)$/
      version, local_path = $1, $2

      entry_point_path = nil
      local_path = File.expand_path(local_path)
      if File.directory?(local_path)
        ly_path = File.join(local_path, "package.ly")
        if File.file?(ly_path)
          entry_point_path = ly_path
        else
          raise "Could not find #{ly_path}. Please specify a valid lilypond file."
        end
      elsif File.file?(local_path)
        entry_point_path = local_path
      else
        raise "Could not find #{local_path}"
      end

      entry_point_dirname = File.dirname(entry_point_path)
      package_path = "#{Lyp.packages_dir}/#{package}@#{version}"
      package_ly_path = "#{package_path}/package.ly"

      FileUtils.rm_rf(package_path)
      FileUtils.mkdir_p(package_path)
      File.open(package_ly_path, 'w+') do |f|
        f << LOCAL_PACKAGE_WRAPPER % [entry_point_dirname, entry_point_path]
      end

      prepare_local_package_fonts(local_path, package_path)

      load_package_ext_file("#{package}@#{version}", local_path)

      {version: version, path: package_path, local_path: local_path}
    end

    def prepare_local_package_fonts(local_path, package_path)
      # create fonts directory symlink if needed
      fonts_path = File.join(local_path, 'fonts')
      if File.directory?(fonts_path)
        FileUtils.ln_sf(fonts_path, File.join(package_path, 'fonts'))
      end
    end

    def install_from_repository(package, version, opts)
      url = package_git_url(package)
      tmp_path = git_url_to_temp_path(url)

      repo = package_repository(url, tmp_path, opts)
      version = checkout_package_version(repo, version, opts)

      # Copy files
      package_path = git_url_to_package_path(
        package !~ /\// ? package : url, version
      )

      FileUtils.mkdir_p(File.dirname(package_path))
      FileUtils.rm_rf(package_path)
      FileUtils.cp_r(tmp_path, package_path)

      load_package_ext_file("#{package}@#{version}", package_path)

      {version: version, path: package_path}
    end

    def load_package_ext_file(package, path)
      ext_path = File.join(path, 'ext.rb')
      if File.file?(ext_path)
        $installed_package = package
        $installed_package_path = path
        load_extension(ext_path)
      end
    end

    def uninstall(package, opts = {})
      unless package =~ Lyp::PACKAGE_RE
        raise "Invalid package specifier #{package}"
      end
      package, version = $1, $2
      package_path = git_url_to_package_path(
        package !~ /\// ? package : package_git_url(package), nil
      )

      if opts[:all]
        Dir["#{package_path}@*"].each do |path|
          name = path.gsub("#{Lyp.packages_dir}/", '')
          puts "Uninstalling #{name}" unless opts[:silent]
          FileUtils.rm_rf(path)
        end

        Dir["#{Lyp.ext_dir}/#{File.basename(package_path)}*.rb"].each do |path|
          FileUtils.rm_f(path)
        end
      else
        if version
          package_path += "@#{version}"
        else
          packages = Dir["#{package_path}@*"] + Dir["#{package_path}"]
          case packages.size
          when 0
            raise "Could not find package #{package}"
          when 1
            package_path = packages[0]
          else
            packages.each do |path|
              name = path.gsub("#{Lyp.packages_dir}/", '')
              puts "Uninstalling #{name}" unless opts[:silent]
              FileUtils.rm_rf(path)
            end
            return
          end
        end

        if File.directory?(package_path)
          name = package_path.gsub("#{Lyp.packages_dir}/", '')
          puts "Uninstalling #{name}" unless opts[:silent]
          FileUtils.rm_rf(package_path)

          Dir["#{Lyp.ext_dir}/#{File.basename(package_path)}.rb"].each do |path|
            FileUtils.rm_f(path)
          end
        else
          raise "Could not find package #{package}"
        end
      end
    end

    def package_repository(url, tmp_path, opts = {})
      Lyp::System.test_rugged_gem!

      # Create repository
      if File.directory?(tmp_path)
        begin
          repo = Rugged::Repository.new(tmp_path)
          repo.fetch('origin', [repo.head.name])
          return repo
        rescue
          # ignore and try to clone
        end
      end

      FileUtils.rm_rf(File.dirname(tmp_path))
      FileUtils.mkdir_p(File.dirname(tmp_path))
      puts "Cloning #{url}..." unless opts[:silent]
      Rugged::Repository.clone_at(url, tmp_path)
    rescue => e
      raise "Could not clone repository (please check that the package URL is correct.)"
    end

    def checkout_package_version(repo, version, opts = {})
      # Select commit to checkout
      checkout_ref = select_checkout_ref(repo, version)
      unless checkout_ref
        raise "Could not find tag matching #{version}"
      end

      begin
        repo.checkout(checkout_ref, strategy: :force)
      rescue
        raise "Invalid version specified (#{version})"
      end

      tag_version(checkout_ref) || version
    end

    def install_package_dependencies(package_path, opts = {})
      # Install any missing sub-dependencies
      sub_deps = []

      resolver = Lyp::DependencyResolver.new("#{package_path}/package.ly")
      deps_tree = resolver.compile_dependency_tree(ignore_missing: true)
      deps_tree.dependencies.each do |package_name, spec|
        sub_deps << spec.clause if spec.versions.empty?
      end
      sub_deps.each {|d| install(d, opts)}
    end

    SYSTEM_LILYPOND_PROMPT = <<-EOF.gsub(/^\s{6}/, '').chomp
      Do you wish to install the package fonts on the system-installed lilypond
      version %s (this might require sudo password)? (y/n):
    EOF

    def install_package_fonts(package_path, opts = {})
      puts "Installing package fonts..." unless opts[:silent]
      available_on_versions = []

      req = Lyp::FONT_COPY_REQ

      Lyp::Lilypond.list.each do |lilypond|
        next unless req =~ Gem::Version.new(lilypond[:version])

        if lilypond[:system]
          next unless Lyp.confirm_action(SYSTEM_LILYPOND_PROMPT % lilypond[:version])
        end

        ly_fonts_dir = File.join(lilypond[:data_path], 'fonts')
        package_fonts_dir = File.join(package_path, 'fonts')

        if lilypond[:system]
          if Lyp::Lilypond.patch_system_lilypond_font_scm(lilypond, opts)
            available_on_versions << lilypond[:version]
          end
        else
          available_on_versions << lilypond[:version]
        end

        Dir["#{package_fonts_dir}/*/**"].each do |fn|
          next unless File.file?(fn)
          target_fn = case File.extname(fn)
          when '.otf'
            File.join(ly_fonts_dir, 'otf', File.basename(fn))
          when '.svg', '.woff'
            File.join(ly_fonts_dir, 'svg', File.basename(fn))
          else
            next
          end

          if File.writable?(File.dirname(target_fn))
            FileUtils.cp(fn, target_fn)
          else
            Lyp.sudo_cp(fn, target_fn)
          end
        end
      end

      unless opts[:silent]
        puts "\nFonts available on lilypond #{available_on_versions.join(', ')}"
      end

    end

    def package_git_url(package, search_index = true)
      case package
      when /^(?:(?:[^\:]+)|http|https)\:/
        package
      when /^([^\.]+\..+)\/[^\/]+\/.+(?<!\.git)$/ # .git missing from end of URL
        "https://#{package}.git"
      when /^([^\.]+\..+)\/.+/
        "https://#{package}"
      when /^[^\/]+\/[^\/]+$/
        "https://github.com/#{package}.git"
      else
        if search_index && (url = search_lyp_index(package))
          package_git_url(url, false) # make sure url is qualified
        else
          raise "Could not find package '#{package}' in lyp-index"
        end
      end
    end

    LYP_INDEX_URL = "https://raw.githubusercontent.com/lyp-packages/index/master/index.yaml"

    def search_lyp_index(package)
      entry = lyp_index['packages'][package]
      entry && entry['url']
    end

    def list_lyp_index(pattern = nil)
      list = lyp_index['packages'].inject([]) do |m, kv|
        m << kv[1].merge('name' => kv[0])
      end

      if pattern
        list.select! {|p| p['name'] =~ /#{pattern}/}
      end

      list.sort_by {|p| p['name']}
    end

    def lyp_index
      @lyp_index ||= YAML.load(open(LYP_INDEX_URL))
    end

    TEMP_REPO_ROOT_PATH = "#{Lyp::TMP_ROOT}/repos"

    def git_url_to_temp_path(url)
      case url
      when /^(?:http|https)\:(?:\/\/)?(.+)$/
        path = $1.gsub(/\.git$/, '')
        "#{TEMP_REPO_ROOT_PATH}/#{path}"
      when /^(?:.+@)([^\:]+)\:(?:\/\/)?(.+)$/
        domain, path = $1, $2.gsub(/\.git$/, '')
        "#{TEMP_REPO_ROOT_PATH}/#{domain}/#{path}"
      else
        raise "Invalid URL #{url}"
      end
    end

    def git_url_to_package_path(url, version)
      # version = 'head' if version.nil? || (version == '')

      package_path = case url
      when /^(?:http|https)\:(?:\/\/)?(.+)$/
        path = $1.gsub(/\.git$/, '')
        "#{Lyp::packages_dir}/#{path}"
      when /^(?:.+@)([^\:]+)\:(?:\/\/)?(.+)$/
        domain, path = $1, $2.gsub(/\.git$/, '')
        "#{Lyp::packages_dir}/#{domain}/#{path}"
      else
        if url !~ /\//
          "#{Lyp::packages_dir}/#{url}"
        else
          raise "Invalid URL #{url}"
        end
      end

      package_path += "@#{version}" if version
      package_path
    end

    TAG_VERSION_RE = /^v?(\d.*)$/

    def select_checkout_ref(repo, version_specifier)
      case version_specifier
      when nil, '', 'latest'
        highest_versioned_tag(repo) || 'master'
      when /^(\>=|~\>|\d)/
        req = Gem::Requirement.new(version_specifier)
        tag = repo_tags(repo).reverse.find do |t|
          (v = tag_version(t.name)) && (req =~ Gem::Version.new(v))
        end
        unless tag
          raise "Could not find a version matching #{version_specifier}"
        else
          tag.name
        end
      else
        version_specifier
      end
    end

    def highest_versioned_tag(repo)
      tag = repo_tags(repo).select {|t| Gem::Version.new(tag_version(t.name)) rescue nil}.last
      tag && tag.name
    end

    # Returns a list of tags sorted by version
    def repo_tags(repo)
      tags = []
      repo.tags.each {|t| tags << t}

      tags.sort do |x, y|
        x_version, y_version = tag_version(x.name), tag_version(y.name)
        if x_version && y_version
          Gem::Version.new(x_version) <=> Gem::Version.new(y_version)
        else
          x.name <=> y.name
        end
      end
    end

    def tag_version(tag)
      (tag =~ TAG_VERSION_RE) ? $1 : nil
    end

    # Runs all tests found in local directory
    def run_local_tests(dir, opts = {})
      package_dir = File.expand_path(dir)
      run_tests(opts) do |stats|
        find_test_files(package_dir).each do |f|
          perform_test(f, stats)
        end
      end
    end

    def find_test_files(dir)
      Dir["#{dir}/**/*_test.ly", "#{dir}/**/*-test.ly"]
    end

    # This method runs tests by yielding the test statistics.
    # The caller should then call #perform_test to run each test file.
    def run_tests(opts = {})
      stats = {
        start: Time.now,
        test_count: 0,
        fail_count: 0
      }

      yield stats

      if stats[:test_count] == 0
        STDERR.puts "No test files found" unless opts[:silent]
      else
        puts "\nFinished in %.2g seconds\n%d files, %d failures" % [
          Time.now - stats[:start], stats[:test_count], stats[:fail_count]
          ] unless opts[:silent]
        exit(stats[:fail_count] > 0 ? 1 : 0) unless opts[:dont_exit]
      end

      stats
    end

    def perform_test(fn, stats)
      stats[:test_count] += 1
      unless Lyp::Lilypond.compile([fn], mode: :system)
        stats[:fail_count] += 1
      end
    end

    def run_package_tests(patterns, opts = {})
      patterns = [''] if patterns.empty?
      packages = patterns.inject([]) do |m, pat|
        m += Dir["#{Lyp.packages_dir}/#{pat}*"]
      end.uniq

      run_tests(opts) do |stats|
        packages.each do |path|
          files = find_test_files(path)
          next if files.empty?

          FileUtils.cd(path) do
            files.each {|fn| perform_test(fn, stats)}
          end
        end
      end
    end

    def load_all_extensions
      Dir["#{Lyp.ext_dir}/*.rb"].each {|f| load_extension(f)}
    end

    def load_extension(path)
      load(path)
    rescue => e
      STDERR.puts "Error while loading extension #{path}"
      STDERR.puts "  #{e.message}"
    end
  end
end

module Lyp
  def self.install_extension(path)
    # install extension only when installing the package
    return unless $installed_package

    FileUtils.cp(path, "#{Lyp.ext_dir}/#{$installed_package}.rb")
  end
end
