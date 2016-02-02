module Process
  def self.getsid
    if `tasklist` =~ /^ruby\.exe\s+#{Process.pid}\s+[^\s]+\s+([0-9]+)/
      $1.to_i
    else
      0
    end
  end
end

module Lyp::Lilypond
  class << self
    def get_system_lilyponds_paths
      []
    end
  
    def lyp_lilypond_path(version)
      "#{Lyp.lilyponds_dir}/#{version}/usr/bin/lilypond.exe"
    end
    
    def lyp_lilypond_share_dir(version)
      File.join(Lyp.lilyponds_dir, version, 'usr/share')
    end
    
    def lyp_lilyponds
      list = []
    
      Dir["#{Lyp.lilyponds_dir}/*"].each do |path|
        next unless File.directory?(path) && File.basename(path) =~ /^[\d\.]+$/
      
        root_path = path
        version = File.basename(path)
        path = File.join(path, "usr/bin/lilypond.exe")
        list << {
          root_path: root_path,
          path: path,
          version: version
        }
      end
    
      list
    end
  
    def download_lilypond(url, fn, opts)
      STDERR.puts "Downloading #{url}" unless opts[:silent]

      if opts[:silent]
        `curl -s -o "#{fn}" "#{url}"`
      else
        `curl -o "#{fn}" "#{url}"`
      end
    end

    def uninstall_lilypond_version(path)
      # run installer
      uninstaller_path = File.join(path, 'uninstall.exe')
      if File.file?(uninstaller_path)
        cmd = "#{uninstaller_path} /S _?=#{path.gsub('/', '\\')}"
        `#{cmd}`
      
        # wait for installer to finish
        t1 = Time.now
        while !File.directory?("#{target_dir}/usr")
          sleep 0.5
          raise "Uninstallation failed" if Time.now - t1 >= 60
        end
      end

      FileUtils.rm_rf(path)
    end
  end
end

module Lyp::Package
  class << self

    def prepare_local_package_fonts(local_path, package_path)
      # create fonts directory symlink if needed
      fonts_path = File.join(local_path, 'fonts')
      if File.directory?(fonts_path)
        FileUtils.cp_r(fonts_path, File.join(package_path, 'fonts'))
      end
    end
    
    def lilypond_fonts_path
      'usr/share/lilypond/current/fonts'
    end
  
    def lyp_index
      @lyp_index ||= YAML.load(`curl -s #{LYP_INDEX_URL}`)
    end
    
  end
end

module Lyp::System
  class << self
    def installed?
      true
    end
    
    def install!
      puts "\ninstall self curently not supported on Windows.\n\n"
    end
    
    def uninstall!
      puts "\nuninstall self curently not supported on Windows.\n\n"
    end
  end
end