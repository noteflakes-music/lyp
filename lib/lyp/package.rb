module Lyp::Package
  class << self
    
    def list(pattern = nil)
      packages = Dir["#{Lyp.packages_dir}/*"].map do |p|
        File.basename(p)
      end
      
      if pattern
        packages.select! {|p| p =~ /#{pattern}/}
      end
      
      packages.sort do |x, y|
        x =~ Lyp::PACKAGE_RE; x_package, x_version = $1, $2
        y =~ Lyp::PACKAGE_RE; y_package, y_version = $1, $2

        x_version = x_version && Gem::Version.new(x_version)
        y_version = y_version && Gem::Version.new(y_version)

        if x_package == y_package
          x_version <=> y_version
        else
          x_package <=> y_package
        end
      end
    end
    
    def package_git_url(package)
      case package
      when /^((git@)|(http\:)|(https\:))/
        package
      when /^([^\.]+\..+)\/[^\/]+\/.+(?<!\.git)$/ # .git missing from end of URL
        "https://#{package}.git"
      when /^([^\.]+\..+)\/.+/
        "https://#{package}"
      when /^[^\/]+\/[^\/]+$/
        "https://github.com/#{package}.git"
      else
        raise "Invalid package specified"
      end
    end
  end
end