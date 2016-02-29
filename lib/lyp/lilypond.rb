require 'uri'
require 'httpclient'
require 'open3'
require 'ruby-progressbar'

module Lyp::Lilypond
  class << self
    def compile(argv, opts = {})
      unless argv.last == '-'
        fn = Lyp.wrap(argv.pop, opts)
        argv << fn
      end
      
      invoke(argv, opts)
    end
    
    def invoke(argv, opts = {})
      lilypond = current_lilypond

      case opts[:mode]
      when :system
        system("#{lilypond} #{argv.join(" ")}")
      else
        Kernel.exec(lilypond, *argv)
      end
    end
    
    def default_lilypond
      Lyp::Settings['lilypond/default']
    end
    
    def set_default_lilypond(path)
      Lyp::Settings['lilypond/default'] = path
    end
    
    # The current lilypond path is stored in a temporary file named by the 
    # session id. Thus we can persist the version selected by the user
    def current_lilypond
      return forced_lilypond if @forced_version
      
      settings = get_session_settings

      if !settings[:current]
        settings[:current] = default_lilypond
        set_session_settings(settings)
      end
      
      settings[:current]
    end
    
    def current_lilypond_version
      path = current_lilypond
      version = File.basename(File.expand_path("#{File.dirname(path)}/../.."))

      unless (Gem::Version.new(version) rescue nil)
        resp = `#{path} -v`
        if resp.lines.first =~ /LilyPond ([0-9\.]+)/i
          version = $1
        end
      end
      version
    end
    
    def set_current_lilypond(path)
      settings = get_session_settings
      settings[:current] = path
      set_session_settings(settings)
    end
    
    def forced_lilypond
      lilypond = filter_installed_list(@forced_version)[0]
      if lilypond
        lilypond[:path]
      else
        raise "No installed version found matching '#{@forced_version}'"
      end
    end
    
    def force_env_version!
      @forced_version = ENV['LILYPOND_VERSION']
      unless @forced_version
        raise "LILYPOND_VERSION not set"
      end
    end
    
    def force_version!(version)
      @forced_version = version
    end
    
    attr_reader :forced_version
    
    def check_lilypond!
      # check default
      select_default_lilypond! unless valid_lilypond?(default_lilypond)
      
      set_current_lilypond(default_lilypond) unless valid_lilypond?(current_lilypond)
    end
    
    def valid_lilypond?(path)
      (File.file?(path) rescue nil) && (`#{path} -v` =~ /^GNU LilyPond/)
    end
    
    def select_default_lilypond!
      latest = system_lilyponds.sort(&CMP_VERSION).last || lyp_lilyponds.sort(&CMP_VERSION).last
      if latest
        default = latest[:path]
        set_default_lilypond(default)
      else
        raise Lyp::LILYPOND_NOT_FOUND_MSG
      end
    end
    
    def get_session_settings
      YAML.load(IO.read(session_settings_filename)) rescue {}
    end
    
    def set_session_settings(settings)
      File.open(session_settings_filename, 'w+') do |f|
        f << YAML.dump(settings)
      end
    end
    
    def session_settings_filename
      "#{Lyp::TMP_ROOT}/session.#{Process.getsid}.yml"
    end
    
    CMP_VERSION = proc do |x, y|
      Gem::Version.new(x[:version]) <=> Gem::Version.new(y[:version])
    end
    
    def filter_installed_list(version_specifier)
      list = (system_lilyponds + lyp_lilyponds).sort!(&CMP_VERSION)
      list.select {|l| version_match(l[:version], version_specifier, list)}
    end
    
    def list(opts = {})
      system_list = opts[:lyp_only] ? [] : system_lilyponds
      lyp_list = opts[:system_only] ? [] : lyp_lilyponds
      
      default = default_lilypond
      unless default
        latest = system_list.sort(&CMP_VERSION).last || lyp_list.sort(&CMP_VERSION).last
        if latest
          default = latest[:path]
          set_default_lilypond(default)
        end
      end
      current = current_lilypond
      
      lilyponds = system_list + lyp_list

      lilyponds.each do |l|
        l[:default] = l[:path] == default
        l[:current] = l[:path] == current
      end
      
      # sort by version
      lilyponds.sort!(&CMP_VERSION)
    end
    
    def lyp_lilyponds
      list = []
      
      Dir["#{Lyp.lilyponds_dir}/*"].each do |path|
        next unless File.directory?(path) && File.basename(path) =~ /^[\d\.]+$/
        
        root_path = path
        version = File.basename(path)
        path = File.join(path, "bin/lilypond")
        list << {
          root_path: root_path,
          data_path: File.join(root_path, 'share/lilypond/current'),
          path: path,
          version: version
        }
      end
      
      list
    end
    
    def system_lilyponds
      list = get_system_lilyponds_paths
      return list if list.empty?
      
      list.inject([]) do |m, path|
        begin
          resp = `#{path} -v`
          if resp.lines.first =~ /LilyPond ([0-9\.]+)/i
            data_path = `#{path} -e"(display (ly:get-option 'datadir))" /dev/null 2>/dev/null`
            
            m << {
              root_path: File.expand_path(File.join(File.dirname(path), '..')),
              data_path: data_path,
              path: path,
              version: $1,
              system: true
            }
          end
        rescue
          # ignore error
        end
        m
      end
    end
    
    def get_system_lilyponds_paths
      self_bin_dir = File.dirname(File.expand_path($0))
      
      list = `which -a lilypond`
      list = list.lines.map {|f| f.chomp}.uniq.reject do |l|
        dir = File.dirname(l)
        (dir == Gem.bindir) || (dir == Lyp::LYP_BIN_DIRECTORY) || (dir == self_bin_dir)
      end
    end
    
    BASE_URL = "http://download.linuxaudio.org/lilypond/binaries"
  
    # Returns a list of versions of lilyponds available for download
    def search(version_specifier = nil)
      require 'open-uri'

      platform = detect_lilypond_platform
      url = "#{BASE_URL}/#{platform}/"
      
      versions = []
      
      open(url).read.scan(/a href=\"lilypond-([0-9\.]+)[^>]+\"/) do |m|        
        versions << $1
      end
      
      installed_versions = list.map {|l| l[:version]}
      versions.select! {|v| version_match(v, version_specifier, versions)}
      versions.map do |v|
        {
          version: v,
          installed: installed_versions.include?(v)
        }
      end
    end
    
    def version_match(version, specifier, all_versions)
      case specifier
      when 'latest'
        version == all_versions.last
      when 'stable'
        Gem::Version.new(version).segments[1].even?
      when 'unstable'
        Gem::Version.new(version).segments[1].odd?
      else
        Gem::Requirement.new(specifier) =~ Gem::Version.new(version)
      end
    end
    
    def latest_stable_version
      search.reverse.find {|l| Gem::Version.new(l[:version]).segments[1].even?}[:version]
    end
    
    def latest_unstable_version
      search.reverse.find {|l| Gem::Version.new(l[:version]).segments[1].odd?}[:version]
    end
    
    def latest_version
      search.last[:version]
    end
    
    def install_if_missing(version_specifier, opts = {})
      if filter_installed_list(version_specifier).empty?
        install(version_specifier, opts)
      end
    end
    
    def install(version_specifier, opts = {})
      version = detect_version_from_specifier(version_specifier)
      raise "No version found matching specifier #{version_specifier}" unless version
      
      STDERR.puts "Installing version #{version}" unless opts[:silent]
      install_version(version, opts)

      lilypond_path = lyp_lilypond_path(version)
      set_current_lilypond(lilypond_path)
      set_default_lilypond(lilypond_path) if opts[:default]
    end
    
    def lyp_lilypond_path(version)
      "#{Lyp.lilyponds_dir}/#{version}/bin/lilypond"
    end
    
    def detect_version_from_specifier(version_specifier)
      case version_specifier
      when /^\d/
        version_specifier
      when nil, 'stable'
        latest_stable_version
      when 'unstable'
        latest_unstable_version
      when 'latest'
        latest_version
      else
        req = Gem::Requirement.new(version_specifier)
        lilypond = search.reverse.find {|l| req =~ Gem::Version.new(l[:version])}
        if lilypond
          lilypond[:version]
        else
          raise "Could not find version matching #{version_specifier}"
        end
      end
    end
    
    def detect_lilypond_platform
      case RUBY_PLATFORM
      when /x86_64-darwin/
        "darwin-x86"
      when /ppc-darwin/
        "darwin-ppc"
      when "i686-linux"
        "linux-x86"
      when "x86_64-linux"
        "linux-64"
      when "ppc-linux"
        "linux-ppc"
      when "x64-mingw32"
        "mingw"
      end
    end
  
    def install_version(version, opts)
      platform = detect_lilypond_platform
      url = lilypond_install_url(platform, version, opts)
      fn = temp_install_filename(url)

      download_lilypond(url, fn, opts) unless File.file?(fn)
      install_lilypond_files(fn, platform, version, opts)
      
      patch_font_scm(version)
      copy_fonts_from_all_packages(version, opts)
    end

    def lilypond_install_url(platform, version, opts)
      ext = case platform
      when /darwin/
        ".tar.bz2"
      when /linux/
        ".sh"
      when /mingw/
        ".exe"
      end
      filename = "lilypond-#{version}-1.#{platform}"
    
      "#{BASE_URL}/#{platform}/#{filename}#{ext}"
    end
    
    def temp_install_filename(url)
      u = URI(url)
      "#{Lyp::TMP_ROOT}/#{File.basename(u.path)}"
    end
  
    def download_lilypond(url, fn, opts)
      STDERR.puts "Downloading #{url}" unless opts[:silent]
      
      download_count = 0
      client = HTTPClient.new
      conn = client.get_async(url)
      msg = conn.pop
      total_size = msg.header['Content-Length'].first.to_i
      io = msg.content

      unless opts[:silent]
        pbar = ProgressBar.create(title: 'Download', total: total_size)
      end
      File.open(fn, 'w+') do |f|
        while data = io.read(10000)
          download_count += data.bytesize
          f << data
          unless opts[:silent]
            pbar.progress = download_count if download_count <= total_size
          end
        end
      end
      pbar.finish unless opts[:silent]
    end
  
    def install_lilypond_files(fn, platform, version, opts)
      tmp_target = "#{Lyp::TMP_ROOT}/lilypond-#{version}"
      FileUtils.mkdir_p(tmp_target)

      case platform
      when /darwin/
        install_lilypond_files_osx(fn, tmp_target, platform, version, opts)
      when /linux/
        install_lilypond_files_linux(fn, tmp_target, platform, version, opts)
      when /mingw/
        install_lilypond_files_windows(fn, tmp_target, platform, version, opts)
      end
      
    ensure
      FileUtils.rm_rf(tmp_target)
    end
  
    def install_lilypond_files_osx(fn, target, platform, version, opts)
      STDERR.puts "Extracting..." unless opts[:silent]
      exec "tar -xjf #{fn} -C #{target}"
    
      copy_lilypond_files("#{target}/LilyPond.app/Contents/Resources", version, opts)
    end
  
    # Since linux versions are distributed as sh archives, we need first to 
    # extract the sh archive, then extract the resulting tar file
    def install_lilypond_files_linux(fn, target, platform, version, opts)
      STDERR.puts "Extracting..." unless opts[:silent]

      # create temp directory in which to extract .sh file
      tmp_dir = "#{Lyp::TMP_ROOT}/#{Time.now.to_f}"
      FileUtils.mkdir_p(tmp_dir)
    
      FileUtils.cd(tmp_dir) do
        exec "sh #{fn} --tarball >/dev/null"
      end
      
      tmp_fn = "#{tmp_dir}/lilypond-#{version}-1.#{platform}.tar.bz2"
      
      exec "tar -xjf #{tmp_fn} -C #{target}"
    
      copy_lilypond_files("#{target}/usr", version, opts)
    ensure
      FileUtils.rm_rf(tmp_dir)
    end
    
    def install_lilypond_files_windows(fn, target, platform, version, opts)
      STDERR.puts "Running NSIS Installer..." unless opts[:silent]
      
      target_dir = File.join(Lyp.lilyponds_dir, version)
      FileUtils.mkdir_p(target_dir)
      
      # run installer
      cmd = "#{fn} /S /D=#{target_dir.gsub('/', '\\')}"
      `#{cmd}`
      
      # wait for installer to finish
      t1 = Time.now
      while !File.file?("#{target_dir}/usr/bin/lilypond.exe")
        sleep 0.5
        raise "Windows installation failed" if Time.now - t1 >= 60
      end

      # Show lilypond versions
      STDERR.puts `#{target_dir}/usr/bin/lilypond -v` unless opts[:silent] || opts[:no_version_test]
    end

    def copy_lilypond_files(base_path, version, opts)
      target_dir = File.join(Lyp.lilyponds_dir, version)
      
      FileUtils.rm_rf(target_dir) if File.exists?(target_dir)
      
      # create directory for lilypond files
      FileUtils.mkdir_p(target_dir)
    
      # copy files
      STDERR.puts "Copying..." unless opts[:silent]
      %w{bin etc lib lib64 share var}.each do |entry|
        dir = File.join(base_path, entry)
        FileUtils.cp_r(dir, target_dir, remove_destination: true) if File.directory?(dir)
      end
      
      # Show lilypond versions
      STDERR.puts `#{target_dir}/bin/lilypond -v` unless opts[:silent] || opts[:no_version_test]
    rescue => e
      puts e.message
    end
    
    def patch_font_scm(version)
      return unless Lyp::FONT_PATCH_REQ =~ Gem::Version.new(version)
      
      target_fn = File.join(lyp_lilypond_share_dir(version), 'lilypond/current/scm/font.scm')
      FileUtils.cp(Lyp::FONT_PATCH_FILENAME, target_fn)
    end
    
    def patch_system_lilypond_font_scm(lilypond)
      return unless Lyp::FONT_PATCH_REQ =~ Gem::Version.new(lilypond[:version])
      
      target_fn = File.join(lilypond[:data_path], '/scm/font.scm')
      puts "patch #{target_fn}"
      FileUtils.cp(Lyp::FONT_PATCH_FILENAME, target_fn)
    end

    def copy_fonts_from_all_packages(version, opts)
      return unless Lyp::FONT_COPY_REQ =~ Gem::Version.new(version)
      
      ly_fonts_dir = File.join(lyp_lilypond_share_dir(version), 'lilypond/current/fonts')
      
      Dir["#{Lyp.packages_dir}/**/fonts"].each do |package_fonts_dir|

        Dir["#{package_fonts_dir}/*.otf"].each do |fn|
          target_fn = File.join(ly_fonts_dir, 'otf', File.basename(fn))
          FileUtils.cp(fn, target_fn)
        end
        
        Dir["#{package_fonts_dir}/*.svg"].each do |fn|
          target_fn = File.join(ly_fonts_dir, 'svg', File.basename(fn))
          FileUtils.cp(fn, target_fn)
        end
        
        Dir["#{package_fonts_dir}/*.woff"].each do |fn|
          target_fn = File.join(ly_fonts_dir, 'svg', File.basename(fn))
          FileUtils.cp(fn, target_fn)
        end
      end
    end
    
    def lyp_lilypond_share_dir(version)
      File.join(Lyp.lilyponds_dir, version, 'share')
    end
    
    def use(version, opts)
      lilypond_list = list.reverse
      
      case version
      when 'system'
        lilypond = lilypond_list.find {|v| v[:system] }
        unless lilypond
          raise "Could not find a system installed version of lilypond"
        end
      when 'latest'
        lilypond = lilypond_list.first
      when 'stable'
        lilypond = lilypond_list.find do |v|
          Gem::Version.new(v[:version]).segments[1].even?
        end
      when 'unstable'
        lilypond = lilypond_list.find do |v|
          Gem::Version.new(v[:version]).segments[1].odd?
        end
      else
        version = "~>#{version}.0" if version =~ /^\d+\.\d+$/
        req = Gem::Requirement.new(version)
        lilypond = lilypond_list.find {|v| req =~ Gem::Version.new(v[:version])}
      end
      
      unless lilypond
        raise "Could not find a lilypond matching \"#{version}\""
      end
      
      set_current_lilypond(lilypond[:path])
      set_default_lilypond(lilypond[:path]) if opts[:default]
      
      lilypond
    end
    
    def uninstall(version_specifier, opts = {})
      list = list(lyp_only: true)
      if version_specifier
        list.select! {|l| version_match(l[:version], version_specifier, list)}
      elsif !opts[:all]
        # if no version is specified
        raise "No version specifier given.\nTo uninstall all versions run 'lyp uninstall lilypond -a'.\n"
      end
      
      if list.empty?
        if version_specifier
          raise "No lilypond found matching #{version_specifier}"
        else
          raise "No lilypond found"
        end
      end
      
      list.each do |l|
        puts "Uninstalling lilypond #{l[:version]}" unless opts[:silent]
        set_current_lilypond(nil) if l[:current]
        set_default_lilypond(nil) if l[:default]
        uninstall_lilypond_version(l[:root_path])
      end
    end
    
    def uninstall_lilypond_version(path)
      FileUtils.rm_rf(path)
    end
    
    def exec(cmd, raise_on_failure = true)
      $_out = ""
      $_err = ""
      success = nil
      Open3.popen3(cmd) do |_in, _out, _err, wait_thr|
        exit_value = wait_thr.value
        $_out = _out.read
        $_err = _err.read
        success = exit_value == 0
      end
      if !success && raise_on_failure
        raise "Error executing cmd #{cmd}:\n#{parse_error_msg($_err)}"
      end
      success
    end
    
    def parse_error_msg(msg)
      (msg =~ /[^\n]+: error.+failed files: ".+"/m) ?
        $& : msg
    end
  end
end