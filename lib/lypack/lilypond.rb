require 'open-uri'
require 'nokogiri'

module Lypack::Lilypond
  class << self
    def compile(argv)
      fn = Lypack.wrap(argv.pop)
      argv << fn
      
      invoke(argv)
      exec("#{current_lilypond} #{argv.join(' ')}")
    end
    
    def invoke(argv)
      lilypond = detect_use_version_argument(argv) || current_lilypond
      
      exec("#{lilypond} #{argv.join(' ')}")
    end
    
    def detect_use_version_argument(argv)
      nil
    end
    
    def default_lilypond
      Lypack::Settings['lilypond/default']
    end
    
    def set_default_lilypond(path)
      Lypack::Settings['lilypond/default'] = path
    end
    
    # The current lilypond path is stored in a temporary file named by the 
    # session id. Thus we can persist the version selected by the user
    def current_lilypond
      settings = get_sid_settings(Process.getsid)

      if !settings[:current]
        settings[:current] = default_lilypond
        set_sid_settings(Process.getsid, settings)
      end
      
      settings[:current]
    end
    
    def set_current_lilypond(path)
      settings = get_sid_settings(Process.getsid)
      settings[:current] = path
      set_sid_settings(Process.getsid, settings)
    end
    
    def get_sid_settings(sid)
      YAML.load(IO.read(sid_settings_filename(Process.getsid))) rescue {}
    end
    
    def set_sid_settings(sid, settings)
      File.open(sid_settings_filename(Process.getsid), 'w+') do |f|
        f << YAML.dump(settings)
      end
    end
    
    def sid_settings_filename(sid)
      "/tmp/lypack.session.#{sid}.yml"
    end
    
    def list
      # combine system + lypack-installed lilyponds and sort by version
      lilyponds = (list_system_lilyponds + list_lypack_lilyponds).sort do |x, y|
        Gem::Version.new(x[:version]) <=> Gem::Version.new(y[:version])
      end
    end
    
    def list_lypack_lilyponds
      default = default_lilypond
      current = current_lilypond
      
      Dir["#{Lypack.lilyponds_dir}/*"].map do |path|
        version = File.basename(path)
        path = File.join(path, "bin/lilypond")
        {
          path: path,
          version: version,
          current: path == current,
          default: path == default
        }
      end
    end
    
    def list_system_lilyponds
      list = `which -a lilypond`
      list = list.lines.map {|f| f.chomp}.reject do |l|
        l =~ /^#{Lypack::LYPACK_BIN_DIRECTORY}/
      end
      
      return list if list.empty?
      
      default = default_lilypond
      if default.nil?
        default = list.first
        set_default_lilypond(default)
      end
      
      current = current_lilypond
      
      list.inject([]) do |m, path|
        begin
          resp = `#{path} -v`
          if resp.lines.first =~ /LilyPond ([0-9\.]+)/i
            m << {
              path: path,
              version: $1,
              system: true,
              current: path == current,
              default: path == default
            }
          end
        rescue
          # ignore error
        end
        m
      end
    end
    
    BASE_URL = "http://download.linuxaudio.org/lilypond/binaries"
  
    def search
      platform = detect_lilypond_platform
      url = "#{BASE_URL}/#{platform}/"
      doc = Nokogiri::HTML(open(url))
      
      versions = []
      doc.xpath("//td//a").each do |a|
        if a[:href] =~ /^lilypond-([0-9\.]+)/
          versions << $1
        end
      end
      versions
    end
    
    def install(version_specifier, opts = {})
      version = detect_version_from_specifier(version_specifier)
      raise "No version found matching specifier #{version_specifier}" unless version

      install_version(version)

      lilypond_path = "#{Lypack.lilyponds_dir}/#{version}/bin/lilypond"
      set_current_lilypond(lilypond_path)
      set_default_lilypond(lilypond_path) if opts[:default]
    end
    
    def detect_version_from_specifier(version_specifier)
      if version_specifier =~ /^\d/
        version_specifier
      else
        req = Gem::Requirement.new(version_specifier)
        search.reverse.find {|v| req =~ Gem::Version.new(v)}
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
  
    def install_version(version)
      platform = detect_lilypond_platform
      url = lilypond_install_url(platform, version)
      fn = Tempfile.new('lypack-lilypond-installer').path

      download_lilypond(url, fn)
      install_lilypond_files(fn, platform, version)
    end

    def lilypond_install_url(platform, version)
      ext = platform =~ /darwin/ ? ".tar.bz2" : ".sh"
      filename = "lilypond-#{version}-1.#{platform}"
    
      "#{BASE_URL}/#{platform}/#{filename}#{ext}"
    end
  
    def download_lilypond(url, fn)
      STDERR.puts "Downloading #{url}"
    
      url_base = url.split('/')[2]
      url_path = '/'+url.split('/')[3..-1].join('/')
      download_count = 0

      Net::HTTP.start(url_base) do |http|
        request_url = URI.escape(url_path)
        response = http.request_head(request_url)
        total_size = response['content-length'].to_i
        pbar = ProgressBar.create(title: 'Download', total: total_size)
        File.open(fn, 'w') do |f|
          http.get(request_url) do |data|
            f << data
            download_count += data.length 
            pbar.progress = download_count if download_count <= total_size
          end
        end
        pbar.finish
      end
    end
  
    def install_lilypond_files(fn, platform, version)
      case platform
      when /darwin/
        install_lilypond_files_osx(fn, version)
      when /linux/
        install_lilypond_files_linux(fn, version)
      end
    end
  
    def install_lilypond_files_osx(fn, version)
      target = "/tmp/lypack/installer/lilypond"
      FileUtils.mkdir_p(target)
    
      STDERR.puts "Extracting..."
      exec "tar -xjf #{fn} -C #{target}"
    
      copy_lilypond_files("#{target}/LilyPond.app/Contents/Resources", version)
    end
  
    def install_lilypond_files_linux(fn, version)
      target = "/tmp/lypack/installer/lilypond"
      FileUtils.mkdir_p(target)
    
      # create temp directory in which to untar file
      tmp_dir = "/tmp/lypack/#{Time.now.to_f}"
      FileUtils.mkdir_p(tmp_dir)
    
      FileUtils.cd(tmp_dir) do
        exec "sh #{fn} --tarball"
      end
    
      STDERR.puts "Extracting..."
      exec "tar -xjf #{tmp_dir}/#{fn} -C #{target}"
    
      copy_lilypond_files("#{target}/usr", version)
    end

    def copy_lilypond_files(base_path, version)
      target_dir = File.join(Lypack.lilyponds_dir, version)
      
      FileUtils.rm_rf(target_dir) if File.exists?(target_dir)
      
      # create directory for lilypond files
      FileUtils.mkdir_p(target_dir)
    
      # copy files
      STDERR.puts "Copying..."
      %w{bin etc lib lib64 share var}.each do |entry|
        dir = File.join(base_path, entry)
        FileUtils.cp_r(dir, target_dir, remove_destination: true) if File.directory?(dir)
      end
      
      STDERR.puts exec "#{target_dir}/bin/lilypond -v"
    rescue => e
      puts e.message
    end
    
    def use(version, opts)
      lilypond_list = list.reverse
      if version == 'system'
        lilypond = lilypond_list.find {|v| v[:system] }
      elsif version == 'stable'
        lilypond = lilypond_list.find do |v|
          Gem::Version.new(v[:version]).segments[1] % 2 == 0
        end
      elsif version == 'unstable'
        lilypond = lilypond_list.find do |v|
          Gem::Version.new(v[:version]).segments[1] % 2 != 0
        end
      else
        if version =~ /^\d+\.\d+$/
          version = "~>#{version}.0"
        end
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
    
    def exec(cmd)
      raise unless system(cmd)
    end
  end
end