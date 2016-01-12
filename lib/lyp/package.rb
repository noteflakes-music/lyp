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
        if (pattern =~ /[@\>\<\=\~]/) && (pattern =~ Lyp::PACKAGE_RE)
          package, version = $1, $2
          req = Gem::Requirement.new(version) rescue nil
          packages.select! do |p|
            p =~ Lyp::PACKAGE_RE
            p_pack, p_ver = $1, $2
            
            next false unless p_pack == package
            
            if req && (p_gemver = Gem::Version.new(p_ver) rescue nil)
              req =~ p_gemver
            else
              p_ver == version
            end
          end
        else
          packages.select! do |p|
            p =~ Lyp::PACKAGE_RE
            $1 =~ /#{pattern}/
          end
        end
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
    
    def which(pattern = nil)
      list(pattern).map {|p| "#{Lyp.packages_dir}/#{p}" }
    end
    
    def install(package_specifier, opts = {})
      unless package_specifier =~ Lyp::PACKAGE_RE
        raise "Invalid package specifier #{package_specifier}"
      end
      package, version = $1, $2
      
      url = package_git_url(package)
      tmp_path = git_url_to_temp_path(url)
      
      repo = package_repository(url, tmp_path, opts)
      version = checkout_package_version(repo, version, opts)
      
      # Copy files
      package_path = git_url_to_package_path(
        package !~ /\// ? package : url, version
      )
      
      FileUtils.mkdir_p(File.dirname(package_path))
      FileUtils.rm_rf(package_path)
      FileUtils.cp_r(tmp_path, package_path)
      
      install_package_dependencies(package_path, opts)
      
      puts "\nInstalled #{package}@#{version}\n\n" unless opts[:silent]
      
      # return the installed version
      version
    end
    
    def uninstall(package, opts = {})
      if opts[:all_versions]
        Dir["#{Lyp.packages_dir}/#{package}@*"].each do |path|
          puts "Uninstalling #{File.basename(path)}" unless opts[:silent]
          FileUtils.rm_rf(path)
        end
      else
        path = "#{Lyp.packages_dir}/#{package}"
        if File.directory?(path)
          puts "Uninstalling #{package}" unless opts[:silent]
          FileUtils.rm_rf(path)
        else
          raise "Could not find #{package}"
        end
      end
    end
    
    def package_repository(url, tmp_path, opts = {})
      # Create repository
      if File.directory?(tmp_path)
        repo = Rugged::Repository.new(tmp_path)
        repo.fetch('origin', [repo.head.name])
      else
        FileUtils.mkdir_p(File.dirname(tmp_path))
        puts "Cloning #{url}..." unless opts[:silent]
        repo = Rugged::Repository.clone_at(url, tmp_path)
      end
      repo
    end
    
    def checkout_package_version(repo, version, opts = {})
      # Select commit to checkout
      checkout_ref = select_checkout_ref(repo, version)
      unless checkout_ref
        raise "Could not find tag matching #{version}"
      end
      
      begin
        repo.checkout(checkout_ref, strategy: :force)
      rescue
        raise "Invalid version specified (#{version})"
      end
      
      tag_version(checkout_ref) || version
    end
    
    def install_package_dependencies(package_path, opts = {})
      # Install any missing sub-dependencies
      sub_deps = []
      
      resolver = Lyp::Resolver.new("#{package_path}/package.ly")
      deps_tree = resolver.get_dependency_tree(ignore_missing: true)
      deps_tree[:dependencies].each do |package_name, leaf|
        sub_deps << leaf[:clause] if leaf[:versions].empty?
      end
      sub_deps.each {|d| install(d, opts)}
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
    
    def select_checkout_ref(repo, version_specifier)
      case version_specifier
      when nil, '', 'latest'
        highest_versioned_tag(repo) || 'master'
      when /^(\>=|~\>|\d)/
        req = Gem::Requirement.new(version_specifier)
        tag = repo_tags(repo).reverse.find do |t|
          (v = tag_version(t.name)) && (req =~ Gem::Version.new(v))
        end
        unless tag
          raise "Could not find a version matching #{version_specifier}"
        else
          tag.name
        end
      else
        version_specifier
      end
    end
    
    def highest_versioned_tag(repo)
      tag = repo_tags(repo).select {|t| Gem::Version.new(tag_version(t.name)) rescue nil}.last
      tag && tag.name
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
      (tag =~ TAG_VERSION_RE) ? $1 : nil
    end
  end
end