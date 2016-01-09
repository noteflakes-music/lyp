require 'fileutils'
require 'open-uri'
require 'yaml'

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
        if search_index && (url = search_lyp_index(package))
          package_git_url(url, false) # make sure url is qualified
        else
          raise "Invalid package specified"
        end
      end
    end
    
    LYP_INDEX_URL = "https://raw.githubusercontent.com/noteflakes/lyp-index/master/index.yaml"
    
    def search_lyp_index(package)
      entry = lyp_index['packages'][package]
      entry && entry['url']
    end
    
    def lyp_index
      @lyp_index ||= YAML.load(open(LYP_INDEX_URL))
    end
    
    TEMP_REPO_ROOT_PATH = "/tmp/lyp/repos"

    def git_url_to_temp_path(url)
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
    
    def git_url_to_package_path(url, version)
      version = 'head' if version.nil? || (version == '')
      
      case url
      when /^(?:http|https)\:(?:\/\/)?(.+)$/
        path = $1.gsub(/\.git$/, '')
        "#{Lyp::packages_dir}/#{path}@#{version}"
      when /^(?:.+@)([^\:]+)\:(?:\/\/)?(.+)$/
        domain, path = $1, $2.gsub(/\.git$/, '')
        "#{Lyp::packages_dir}/#{domain}/#{path}@#{version}"
      else
        raise "Invalid URL #{url}"
      end
    end
    
    TAG_VERSION_RE = /^v?(\d.*)$/
    
    def select_git_tag(repo, version_specifier)
      req = Gem::Requirement.new(version_specifier) rescue nil
      
      sorted_tags(repo).reverse.find do |t|
        if req && v = tag_version(t)
          req =~ v
        else
          t.name == version_specifier
        end
      end
    end
    
    # Returns a list of tags sorted by version
    def repo_tags(repo)
      tags = []
      repo.tags.each {|t| tags << t}
      
      tags.sort do |x, y|
        x_version, y_version = tag_version(x), tag_version(y)
        if x_version && y_version
          Gem::Version.new(x_version) <=> Gem::Version.new(y_version)
        else
          x <=> y
        end
      end
    end
    
    def tag_version(tag)
      (tag =~ TAG_VERSION_RE) ? $1 : nil
    end
  end
end