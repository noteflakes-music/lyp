require 'fileutils'

module Lyp::System
  class << self
    RUGGED_REQ = Gem::Requirement.new('>=0.23.0')
    
    def test_rugged_gem!
      return if find_rugged_gem || use_git_based_rugged_gem
      
      STDERR.puts "Lyp needs git in order to be able to install packages. Please install git and then try again."
      exit 1
    end
    
    def find_rugged_gem
      found = Gem::Specification.find_all_by_name('rugged').find do |s|
        RUGGED_REQ =~ s.version
      end
      
      require_rugged_gem if found
      found
    end
    
    def require_rugged_gem
      gem 'rugged', RUGGED_REQ.to_s
      require 'rugged'
    end
    
    def use_git_based_rugged_gem
      git_available = `git --version` rescue nil
      return false unless git_available
      
      require File.expand_path('git_based_rugged', File.dirname(__FILE__))
    end
    
    INSTALL_MSG = <<EOF

Warning! Lyp is not yet properly installed in your home directory. 

To install lyp run 'lyp install self'. lyp will then:
  1. Setup ~/.lyp as its base directory.
  2. Add the lyp and lilypond scripts to ~/.lyp/bin.
  3. Add ~/.lyp/bin to front of $PATH.
  
You can uninstall lyp at any time by running 'lyp uninstall self'.

EOF

    def test_installed_status!
      if !is_gem? && !installed?
        STDERR.puts INSTALL_MSG
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
      setup_files
      
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
    
    def setup_files
      if is_gem?
        setup_gem_files
      else
        setup_release_files
      end
    end
    
    RELEASE_BIN_PATH = "lib/app/bin"
    SELF_DIR = File.expand_path(File.dirname($0))
    
    def is_gem?
      SELF_DIR !~ /#{RELEASE_BIN_PATH}$/
    end
    
    def setup_gem_files
      FileUtils.rm_rf(Lyp::LYP_BIN_DIRECTORY)
      FileUtils.mkdir_p(Lyp::LYP_BIN_DIRECTORY)

      %w{lyp lilypond}.each do |fn|
        FileUtils.ln_sf("#{SELF_DIR}/#{fn}", "#{Lyp::LYP_BIN_DIRECTORY}/#{fn}")
      end
    end
    
    def setup_release_files
      FileUtils.rm_rf(Lyp::LYP_BIN_DIRECTORY)
      FileUtils.mkdir_p(Lyp::LYP_BIN_DIRECTORY)
      
      release_dir = File.expand_path(File.join(SELF_DIR, '../../../'))
      
      puts "Copying Ruby runtime & gems..."
      lib_dir = File.join(release_dir, 'lib')
      FileUtils.rm_rf(Lyp::LYP_LIB_DIRECTORY)
      FileUtils.cp_r(lib_dir, Lyp::LYP_LIB_DIRECTORY)
      
      puts "Copying binary scripts..."
      wrapper_bin_dir = File.join(release_dir, 'bin')
      %w{lyp lilypond}.each do |f|
        FileUtils.cp("#{wrapper_bin_dir}/#{f}", "#{Lyp::LYP_BIN_DIRECTORY}/#{f}")
      end
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
      Dir["#{Lyp::LYP_BIN_DIRECTORY}/*"].each do |fn|
        FileUtils.rm_f(fn) rescue nil
      end
      
      puts "\nTo completely remove installed packages and lilyponds run 'rm -rf ~/.lyp'.\n\n"
    end
  end
end

