require 'fileutils'

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
      when /^(?:(?:[^\:]+)|http|https)\:/
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
    
    TEMP_REPO_ROOT_PATH = "/tmp/lyp/repos"

    def git_url_to_local_path(url)
      case url
      when /^(?:http|https)\:(?:\/\/)?(.+)$/
        path = $1.gsub(/\.git$/, '')
        "#{TEMP_REPO_ROOT_PATH}/#{path}"
      when /^(?:.+@)([^\:]+)\:(?:\/\/)?(.+)$/
        domain, path = $1, $2.gsub(/\.git$/, '')
        "#{TEMP_REPO_ROOT_PATH}/#{domain}/#{path}"
      else
        raise "Invalid URL #{url}"
      end
    end
    
  end
end