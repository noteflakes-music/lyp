require 'httpclient'
require 'uri'

module Lyp::Lilypond
  class << self
    def compile(argv)
      fn = Lyp.wrap(argv.pop)
      argv << fn
      
      invoke(argv)
    end
    
    def invoke(argv)
      lilypond = detect_use_version_argument(argv) || current_lilypond
      
      exec("#{lilypond} #{argv.join(' ')}")
    end
    
    def detect_use_version_argument(argv)
      nil
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
      settings = get_session_settings

      if !settings[:current]
        settings[:current] = default_lilypond
        set_session_settings(settings)
      end
      
      settings[:current]
    end
    
    def set_current_lilypond(path)
      settings = get_session_settings
      settings[:current] = path
      set_session_settings(settings)
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
      "/tmp/lyp.session.#{Process.getsid}.yml"
    end
    
    CMP_VERSION = proc do |x, y|
      Gem::Version.new(x[:version]) <=> Gem::Version.new(y[:version])
    end
    
    def list
      system_list = system_lilyponds
      lyp_list = lyp_lilyponds
      
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
        
        version = File.basename(path)
        path = File.join(path, "bin/lilypond")
        list << {
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
            m << {
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
      list = list.lines.map {|f| f.chomp}.reject do |l|
        dir = File.dirname(l)
        (dir == Lyp::LYP_BIN_DIRECTORY) || (dir == self_bin_dir)
      end
    end
    
    BASE_URL = "http://download.linuxaudio.org/lilypond/binaries"
  
    # Returns a list of versions of lilyponds available for download
    def search(version_specifier = nil)
      require 'open-uri'
      require 'nokogiri'

      platform = detect_lilypond_platform
      url = "#{BASE_URL}/#{platform}/"
      doc = Nokogiri::HTML(open(url))
      
      versions = []
      doc.xpath("//td//a").each do |a|
        if a[:href] =~ /^lilypond-([0-9\.]+)/
          versions << $1
        end
      end

      installed_versions = list.map {|l| l[:version]}
      versions.select {|v| version_match(v, version_specifier, versions)}.map do |v|
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
    
    def install(version_specifier, opts = {})
      version = detect_version_from_specifier(version_specifier)
      raise "No version found matching specifier #{version_specifier}" unless version
      
      STDERR.puts "Installing version #{version}" unless opts[:silent]
      install_version(version, opts)

      lilypond_path = "#{Lyp.lilyponds_dir}/#{version}/bin/lilypond"
      set_current_lilypond(lilypond_path)
      set_default_lilypond(lilypond_path) if opts[:default]
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
      end
    end
  
    def install_version(version, opts)
      platform = detect_lilypond_platform
      url = lilypond_install_url(platform, version, opts)
      fn = temp_install_filename(url)

      download_lilypond(url, fn, opts) unless File.file?(fn)
      install_lilypond_files(fn, platform, version, opts)
    end

    def lilypond_install_url(platform, version, opts)
      ext = platform =~ /darwin/ ? ".tar.bz2" : ".sh"
      filename = "lilypond-#{version}-1.#{platform}"
    
      "#{BASE_URL}/#{platform}/#{filename}#{ext}"
    end
    
    def temp_install_filename(url)
      u = URI(url)
      "/tmp/lyp-installer-#{File.basename(u.path)}"
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
      tmp_target = "/tmp/lyp-lilypond-#{version}"
      FileUtils.mkdir_p(tmp_target)

      case platform
      when /darwin/
        install_lilypond_files_osx(fn, tmp_target, platform, version, opts)
      when /linux/
        install_lilypond_files_linux(fn, tmp_target, platform, version, opts)
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
      tmp_dir = "/tmp/lyp-#{Time.now.to_f}"
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
      
      STDERR.puts exec "#{target_dir}/bin/lilypond -v"  unless opts[:silent]
    rescue => e
      puts e.message
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
    
    def uninstall(version)
      lilyponds = list.reverse
      lilypond = lilyponds.find {|l| l[:version] == version && !l[:system]}
      unless lilypond
        raise "Invalid version specified: #{version}"
      end
      lilyponds.delete(lilypond)
      latest = lilyponds.first
      
      if lilypond[:default]
        set_default_lilypond(latest && latest[:path])
      end
      if lilypond[:current]
        set_current_lilypond(latest && latest[:path])
      end
      
      lilypond_dir = File.expand_path('../..', lilypond[:path])
      FileUtils.rm_rf(lilypond_dir)
    end
    
    def exec(cmd)
      raise unless system(cmd)
    end
  end
end