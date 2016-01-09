require 'fileutils'
require 'rugged'
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

        x_version = (x_version && Gem::Version.new(x_version) rescue x)
        y_version = (y_version && Gem::Version.new(y_version) rescue y)

        if (x_package == y_package) && (x_version.class == y_version.class)
          x_version <=> y_version
        else
          x <=> y
        end
      end
    end
    
    def install(package_specifier)
      unless package_specifier =~ Lyp::PACKAGE_RE
        raise "Invalid package specifier #{package_specifier}"
      end
      package, version = $1, $2
      
      url = package_git_url(package)
      tmp_path = git_url_to_temp_path(url)
      
      repo = package_repository(url, tmp_path)
      version = checkout_package_version(repo, version)
      
      # Copy files
      package_path = git_url_to_package_path(
        package !~ /\// ? package : url, version
      )
      
      FileUtils.mkdir_p(File.dirname(package_path))
      FileUtils.rm_rf(package_path)
      FileUtils.cp_r(tmp_path, package_path)
      
      install_package_dependencies(package_path)
      
      puts "\nInstalled #{package}@#{version}\n\n"
      
      # return the installed version
      version
    end
    
    def package_repository(url, tmp_path)
      # Create repository
      if File.directory?(tmp_path)
        repo = Rugged::Repository.new(tmp_path)
        repo.fetch('origin', [repo.head.name])
      else
        FileUtils.mkdir_p(File.dirname(tmp_path))
        puts "Cloning #{url}..."
        repo = Rugged::Repository.clone_at(url, tmp_path)
      end
      repo
    end
    
    def checkout_package_version(repo, version)
      # Select commit to checkout
      if version.nil? || (version == '')
        puts "Checkout master branch..."
        repo.checkout('master', strategy: :force)
        version = 'head'
      else
        tag = select_git_tag(repo, version)
        unless tag
          raise "Could not find tag matching #{version_specifier}"
        end
        puts "Checkout #{tag.name} tag"
        repo.checkout(tag.name, strategy: :force)
        version = tag_version(tag)
      end
      version
    end
    
    def install_package_dependencies(package_path)
      # Install any missing sub-dependencies
      sub_deps = []
      
      resolver = Lyp::Resolver.new("#{package_path}/package.ly")
      deps_tree = resolver.get_dependency_tree(ignore_missing: true)
      deps_tree[:dependencies].each do |package_name, leaf|
        sub_deps << leaf[:clause] if leaf[:versions].empty?
      end
      sub_deps.each {|d| install(d)}
    end
    
    def package_git_url(package, search_index = true)
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
    
    def list_lyp_index(pattern = nil)
      list = lyp_index['packages'].inject([]) do |m, kv|
        m << kv[1].merge(name: kv[0])
      end
      
      if pattern
        list.select! {|p| p[:name] =~ /#{pattern}/}
      end
      
      list.sort_by {|p| p[:name]}
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
        if url !~ /\//
          "#{Lyp::packages_dir}/#{url}@#{version}"
        else
          raise "Invalid URL #{url}"
        end
      end
    end
    
    TAG_VERSION_RE = /^v?(\d.*)$/
    
    def select_git_tag(repo, version_specifier)
      return if version_specifier.nil? || (version_specifier == '')
      
      req = Gem::Requirement.new(version_specifier) rescue nil
      
      repo_tags(repo).reverse.find do |t|
        if req && (v = tag_version(t))
          req =~ Gem::Version.new(v)
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
          x.name <=> y.name
        end
      end
    end
    
    def tag_version(tag)
      (tag.name =~ TAG_VERSION_RE) ? $1 : nil
    end
  end
end