module Lyp::Lilypond
  class << self
    NO_ARGUMENT_OPTIONS_REGEXP = /^\-([REnFOcSA]+)(.+)/

    def preprocess_argv(argv)
      options = {}
      argv = argv.dup # copy for iterating
      argv_clean = []
      while arg = argv.shift
        parse_lilypond_arg(arg, argv, argv_clean, options)
      end

      [options, argv_clean]
    end

    def parse_lilypond_arg(arg, argv, argv_clean, options)
      case arg
      when NO_ARGUMENT_OPTIONS_REGEXP
        # handle multiple options in shorthand form, e.g. -FnO
        tmp_args = []
        $1.each_char {|c| tmp_args << "-#{c}"}
        tmp_args << "-#{$2}"
        argv = tmp_args + argv
      when '-A', '--auto-install-deps'
        options[:resolve] = true
      when '-c', '--cropped'
        argv_clean += ['-dbackend=eps', '-daux-files=#f']
      when '-E', '--env'
        unless ENV['LILYPOND_VERSION']
          STDERR.puts "$LILYPOND_VERSION not set"
          exit 1
        end
        options[:use_version] = ENV['LILYPOND_VERSION']
      when '-F', '--force-version'
        options[:force_version] = true
      when '-n', '--install'
        options[:install] = true
      when '-O', '--open'
        options[:open] = true
      when '-r', '--require'
        options[:ext_require] ||= []
        options[:ext_require] << argv.shift
      when /^(?:\-r|\-\-require\=)"?([^\s]+)"?/
        options[:ext_require] ||= []
        options[:ext_require] << $1
      when '-R', '--raw'
        options[:raw] = true
      when '-S', '--snippet'
        argv_clean += ['-dbackend=eps', '-daux-files=#f', '--png', '-dresolution=600']
        options[:snippet_paper_preamble] = true
      when '-u', '--use'
        options[:use_version] = argv.shift
      when /^(?:\-u|\-\-use\=)"?([^\s]+)"?/
        options[:use_version] = $1
      when '--invoke-system'
        options[:mode] = :system
      when '--invoke-quiet'
        options[:mode] = :quiet
      else
        argv_clean << arg
      end
    end

    VERSION_STATEMENT_REGEX = /\\version "([^"]+)"/

    def select_lilypond_version(opts, file_path)
      forced_version = opts[:force_version] ?
        get_file_expected_version(file_path) : opts[:use_version]

      if forced_version
        Lyp::Lilypond.install_if_missing(forced_version) if opts[:install]
        Lyp::Lilypond.force_version!(forced_version)
      end

      Lyp::Lilypond.check_lilypond!

      opts[:lilypond_version] = current_lilypond_version

      Lyp::Lilypond.current_lilypond.tap do |path|
        unless path && File.file?(path)
          STDERR.puts "No version of lilypond found. To install lilypond run 'lyp install lilypond'."
          exit 1
        end
      end
    rescue => e
      STDERR.puts e.message
      exit 1
    end

    def get_file_expected_version(file_path)
      if IO.read(file_path) =~ VERSION_STATEMENT_REGEX
        $1
      else
        raise "Could not find version statement in #{file_path}"
      end
    rescue => e
      raise "Failed to read #{file_path}"
    end

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
      when :quiet
        `#{lilypond} #{argv.join(" ")} > /dev/null 2>&1`
      when :spawn
        pid = spawn(lilypond, *argv, opts[:spawn_opts] || {})
        Process.detach(pid)
      else
        Kernel.exec(lilypond, *argv)
      end
    end

    def invoke_script(argv, opts = {})
      cmd = File.join(current_lilypond_bin_path, argv.shift)

      case opts[:mode]
      when :system
        system("#{cmd} #{argv.join(" ")}")
      when :spawn
        pid = spawn(cmd, *argv, opts[:spawn_opts] || {})
        Process.detach(pid)
      else
        Kernel.exec(cmd, *argv)
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

    def current_lilypond_bin_path
      lilypond = current_lilypond
      lilypond && File.dirname(lilypond)
    end

    def current_lilypond_version
      path = current_lilypond
      version = File.basename(File.expand_path("#{File.dirname(path)}/../.."))

      unless (Lyp.version(version) rescue nil)
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

    # Make sure there's a default and current lilypond set
    def check_lilypond!
      path = default_lilypond
      select_default_lilypond! unless path && path =~ /lilypond$/

      path = current_lilypond
      set_current_lilypond(default_lilypond) unless path && path =~ /lilypond$/
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
      req_ext('yaml')
      settings = YAML.load(IO.read(session_settings_filename)) rescue {}
      settings = {} unless settings.is_a?(Hash)
      settings
    end

    def set_session_settings(settings)
      req_ext('yaml')
      File.open(session_settings_filename, 'w+') do |f|
        f << YAML.dump(settings)
      end
    end

    def session_settings_filename
      "#{Lyp::TMP_ROOT}/session.#{Process.getsid}.yml"
    end

    CMP_VERSION = proc do |x, y|
      Lyp.version(x[:version]) <=> Lyp.version(y[:version])
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
          resp = `#{path} #{Lyp::DETECT_SYSTEM_LILYPOND_FILENAME} 2>/dev/null`

          if resp =~ /(.+)\n(.+)/
            version, data_path = $1, $2
            m << {
              root_path: File.expand_path(File.join(File.dirname(path), '..')),
              data_path: data_path,
              path: path,
              version: $1,
              system: true
            }
          end
        rescue
          # ignore error, don't include this version in the list of lilyponds
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
      req_ext 'open-uri'

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
        Lyp.version(version).segments[1].even?
      when 'unstable'
        Lyp.version(version).segments[1].odd?
      else
        Lyp.version_req(specifier) =~ Lyp.version(version)
      end
    end

    def latest_stable_version
      search.reverse.find {|l| Lyp.version(l[:version]).segments[1].even?}[:version]
    end

    def latest_unstable_version
      search.reverse.find {|l| Lyp.version(l[:version]).segments[1].odd?}[:version]
    end

    def latest_installed_unstable_version
      latest = list.reverse.find {|l| Lyp.version(l[:version]).segments[1].odd?}
      latest ? latest[:version] : nil
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
        req = Lyp.version_req(version_specifier)
        lilypond = search.reverse.find {|l| req =~ Lyp.version(l[:version])}
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
      req_ext('uri')
      u = URI(url)
      "#{Lyp::TMP_ROOT}/#{File.basename(u.path)}"
    end

    def download_lilypond(url, fn, opts)
      req_ext 'ruby-progressbar'
      req_ext 'httpclient'

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
      run_cmd "tar -xjf #{fn} -C #{target}"

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
        run_cmd "sh #{fn} --tarball >/dev/null"
      end

      tmp_fn = "#{tmp_dir}/lilypond-#{version}-1.#{platform}.tar.bz2"

      run_cmd "tar -xjf #{tmp_fn} -C #{target}"

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
      return unless Lyp::FONT_PATCH_REQ =~ Lyp.version(version)

      target_fn = File.join(lyp_lilypond_share_dir(version), 'lilypond/current/scm/font.scm')
      FileUtils.cp(Lyp::FONT_PATCH_FILENAME, target_fn)
    end

    SYSTEM_LILYPOND_PATCH_WARNING = <<-EOF.gsub(/^\s{6}/, '').chomp
      The system-installed lilypond version %s needs to be patched in
      order to support custom music fonts. This operation will replace the file

        %s

      Would you like to overwrite this file? (y/n):
    EOF

    def patch_system_lilypond_font_scm(lilypond, opts)
      return false unless Lyp::FONT_PATCH_REQ =~ Lyp.version(lilypond[:version])

      target_fn = File.join(lilypond[:data_path], '/scm/font.scm')
      # do nothing if alredy patched
      if IO.read(target_fn) == IO.read(Lyp::FONT_PATCH_FILENAME)
        return true
      end

      prompt = SYSTEM_LILYPOND_PATCH_WARNING % [lilypond[:version], target_fn]
      return unless Lyp.confirm_action(prompt)

      puts "Patching #{target_fn}:" unless opts[:silent]
      if File.writeable?(target_fn)
        FileUtils.cp(target_fn, "#{target_fn}.old")
        FileUtils.cp(Lyp::FONT_PATCH_FILENAME, target_fn)
      else
        Lyp.sudo_cp(target_fn, "#{target_fn}.old")
        Lyp.sudo_cp(Lyp::FONT_PATCH_FILENAME, target_fn)
      end
    end

    def copy_fonts_from_all_packages(version, opts)
      return unless Lyp::FONT_COPY_REQ =~ Lyp.version(version)

      ly_fonts_dir = File.join(lyp_lilypond_share_dir(version), 'lilypond/current/fonts')

      Dir["#{Lyp.packages_dir}/**/fonts"].each do |package_fonts_dir|
        Dir["#{package_fonts_dir}/**/*"].each do |fn|
          next unless File.file?(fn)
          target_fn = case File.extname(fn)
          when '.otf'
            File.join(ly_fonts_dir, 'otf', File.basename(fn))
          when '.svg', '.woff'
            File.join(ly_fonts_dir, 'svg', File.basename(fn))
          else
            next
          end

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
          Lyp.version(v[:version]).segments[1].even?
        end
      when 'unstable'
        lilypond = lilypond_list.find do |v|
          Lyp.version(v[:version]).segments[1].odd?
        end
      else
        version = "~>#{version}.0" if version =~ /^\d+\.\d+$/
        req = Lyp.version_req(version)
        lilypond = lilypond_list.find {|v| req =~ Lyp.version(v[:version])}
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

    def run_cmd(cmd, raise_on_failure = true)
      req_ext('open3')
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
        raise "Error executing #{cmd}:\n#{parse_error_msg($_err)}"
      end
      success
    end

    def parse_error_msg(msg)
      (msg =~ /[^\n]+: error.+failed files: ".+"/m) ? $& : msg
    end

    CHECK_UPDATE_INTERVAL = 7 * 86400
    CHECK_UPDATE_STAMP_KEY = 'lilypond/last_update_stamp'

    UNSTABLE_UPDATE_MESSAGE = <<EOF
Lilypond version %s is now available. Install it by typing:

  lyp install lilypond@unstable

EOF

    def check_update
      last_check = Lyp::Settings.get_value(
        CHECK_UPDATE_STAMP_KEY, Time.now - CHECK_UPDATE_INTERVAL)

      return unless last_check < Time.now - CHECK_UPDATE_INTERVAL

      Lyp::Settings.set_value(CHECK_UPDATE_STAMP_KEY, Time.now)

      # check unstable
      installed = latest_installed_unstable_version
      return unless installed

      available = {version: latest_unstable_version}
      installed = {version: installed}

      if CMP_VERSION[available, installed] > 0
        puts UNSTABLE_UPDATE_MESSAGE % available[:version]
      end
    end
  end
end
