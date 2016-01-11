require 'fileutils'

module Lyp::System
  class << self
    INSTALL_MSG = <<EOF

lyp is not yet properly installed in your home directory. 

To install lyp run 'lyp install self'. lyp will then:
  1. Setup ~/.lyp as its base directory.
  2. Add ~/.lyp/bin to $PATH.
  
You can uninstall lyp at any time by running 'lyp uninstall self'.

EOF

    def test_installed_status!
      return
      unless installed?
        puts INSTALL_MSG
        exit 1
      end
    end
    
    def installed?(opts = {})
      path_is_there = ":#{::ENV['PATH']}:" =~ /#{Lyp::LYP_BIN_DIRECTORY}/
      file_is_there = File.file?("#{Lyp::LYP_BIN_DIRECTORY}/lyp")
      
      (opts[:no_path_check] || path_is_there) && file_is_there
    end
    
    # Adds ~/.lyp/bin to $PATH to the first profile file that exists, then
    # returns the profile filename
    def install!
      puts "\nInstalling lyp...\n\nAdding ~/.lyp/bin to $PATH..."
      profile_fn = setup_bin_path
      puts "Setting up binary scripts..."
      setup_bin_scripts
      
      if installed?(no_path_check: true)
        puts "\nTo finish installation, open a new shell or run 'source ~/#{File.basename(profile_fn)}'.\n\n"
      else
        raise "Failed to install lyp"
      end
    end
    
    PROFILE_FILES = %w{
      .profile .bash_profile .bash_login .bashrc .zshenv .zshrc .mkshrc
    }.map {|fn| File.join(Dir.home, fn)}

    LYP_LOAD_CODE = <<EOF

[[ ":${PATH}:" == *":${HOME}/.lyp/bin:"* ]] || PATH="$HOME/.lyp/bin:$PATH"
EOF

    def setup_bin_path
      fn = PROFILE_FILES.find {|f| File.file?(f)}
      unless fn
        raise "Could not find a shell profile file"
      end
      
      unless (IO.read(fn) =~ /\.lyp\/bin/)
        File.open(fn, 'a') {|f| f << LYP_LOAD_CODE}
      end
      fn
    end
    
    def setup_bin_scripts
      bin_dir = File.expand_path(File.dirname($0))
      
      if is_gem?(bin_dir)
        setup_gem_bin_scripts(bin_dir)
      else
        setup_release_bin_scripts(bin_dir)
      end
    end
    
    RELEASE_BIN_PATH = "lib/app/bin/"
    
    def is_gem?(bin_dir)
      bin_dir !~ /#{RELEASE_BIN_PATH}[a-z]+$/
    end
    
    def setup_gem_bin_scripts(bin_dir)
      FileUtils.mkdir_p(Lyp::LYP_BIN_DIRECTORY)
      %w{lyp lilypond}.each do |fn|
        FileUtils.ln_sf("#{bin_dir}/#{fn}", "#{Lyp::LYP_BIN_DIRECTORY}/#{fn}")
      end
    end
    
    def setup_release_bin_scripts(bin_dir)
      # to be implemented
    end
    
    def uninstall!
      puts "\nUninstalling lyp...\n\nRemoving ~/.lyp/bin from $PATH..."
      
      # Remove ~/.lyp/bin from $PATH
      PROFILE_FILES.each do |fn|
        next unless File.file?(fn)
        
        content = IO.read(fn)
        if (content =~ /\.lyp\/bin/)
          content.gsub!(/\n?.*\.lyp\/bin.*\n/, '')
          File.open(fn, 'w+') {|f| f << content}
        end
      end
      
      puts "Removing binary scripts..."
      # Delete bin scripts
      FileUtils.rm("#{Lyp::LYP_BIN_DIRECTORY}/*") rescue nil
      
      puts "\nTo completely remove installed packages and lilyponds run 'rm -rf ~/.lyp'.\n\n"
    end
  end
end

