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
  
  end
end