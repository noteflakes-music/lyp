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
    
    # - Copy the entire directory to ~/.lyp
    # - Create wrappers in Windows/System32 that call ~/.lyp/bin
    def install!
      return if is_gem?
      
      puts "\nInstalling lyp...\n\n"
      copy_package_files
      create_wrapper_batch_files
    end
    
    def copy_package_files
      package_root = File.expand_path('../../../..', File.dirname(__FILE__))
      FileUtils.rm_rf("#{Lyp::LYP_DIRECTORY}/lib")
      FileUtils.rm_rf("#{Lyp::LYP_DIRECTORY}/bin")
      FileUtils.cp_r("#{package_root}/lib", "#{Lyp::LYP_DIRECTORY}/lib")
      FileUtils.cp_r("#{package_root}/bin", "#{Lyp::LYP_DIRECTORY}/bin")
    end
    
    def create_wrapper_batch_files
      system32_dir = File.join(ENV["SystemRoot"], "System32")
      bin_dir = "#{Lyp::LYP_DIRECTORY}/bin"
      
      %w{lyp lilypond}.each do |name|
        File.open("#{system32_dir}/#{name}.bat", "w+") do |f|
          f << "@#{bin_dir}\\#{name}.bat %*"
        end
      end
    end

    def uninstall!
      puts "\nuninstall self curently not supported on Windows.\n\n"
    end
  end
end