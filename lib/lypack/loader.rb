module Lypack::Loader
  class << self
    DEP_RE = /\\(require|include) "([^"]+)"/.freeze
    INCLUDE = "include".freeze
    REQUIRE = "require".freeze
    
    # Process a user file and return a dependency tree
    def process(path)
      tree = {
        dependencies: {},
        queue: [],
        processed_files: {}
      }
      
      queue_file_for_processing(path, tree, tree)

      while job = pull_file_from_queue(tree)
        process_lilypond_file(job[:path], tree, job[:ptr])
      end
      
      remove_unfulfilled_dependencies(tree)
      
      tree
    end
    
    def process_lilypond_file(path, tree, ptr)
      # path is expected to be absolute
      return if file_processed?(path, tree)
      
      ly_content = IO.read(path)
      dir = File.dirname(path)
      
      ly_content.scan(DEP_RE) do |type, path|
        case type
        when INCLUDE
          qualified_path = File.expand_path(path, dir)
          queue_file_for_processing(qualified_path, tree, ptr)
        when REQUIRE
          find_package_versions(path, tree, ptr)
        end
      end
      
      tree[:processed_files][path] == true
    end
    def file_processed?(path, tree)
      tree[:processed_files][path]
    end
    
    def queue_file_for_processing(path, tree, ptr)
      (tree[:queue] ||= []) << {path: path, ptr: ptr}
    end
    
    def pull_file_from_queue(tree)
      tree[:queue].shift
    end
    
    PACKAGE_RE = /^([^@]+)(?:@(.+))?$/
    
    def find_package_versions(ref, tree, ptr)
      return {} unless ref =~ PACKAGE_RE
      ref_package = $1
      version_clause = $2

      matches = find_matching_packages(ref, tree)
      
      # Make sure found packages are processed
      matches.each do |p, subtree|
        if subtree[:path]
          queue_file_for_processing(subtree[:path], tree, subtree)
        end
      end
      
      (ptr[:dependencies] ||= {}).merge!({
        ref_package => {
          clause: ref,
          versions: matches
        }
      })
    end
    
    def find_matching_packages(ref, tree)
      return {} unless ref =~ PACKAGE_RE
      
      ref_package = $1
      version_clause = $2
      req = Gem::Requirement.new(version_clause || '>=0')

      available_packages(tree).select do |package_name, sub_tree|
        if package_name =~ PACKAGE_RE
          version = Gem::Version.new($2 || '0')
          (ref_package == $1) && (req =~ version)
        else
          nil
        end
      end
    end
    
    MAIN_PACKAGE_FILE = 'package.ly'
    
    def available_packages(tree)
      tree[:available_packages] ||= get_available_packages(packages_dir)
    end
    
    def get_available_packages(dir)
      Dir["#{packages_dir}/*"].inject({}) do |m, p|
        m[File.basename(p)] = {
          path: File.join(p, MAIN_PACKAGE_FILE), 
          dependencies: {},
          
        }
        m
      end
    end

    DEFAULT_PACKAGE_DIRECTORY = File.expand_path('~/.lypack/packages')

    def packages_dir
      DEFAULT_PACKAGE_DIRECTORY
    end
    
    # Recursively remove any dependency for which no version is locally 
    # available. If no version is found for any of the dependencies specified
    # by the user, an error is raised.
    def remove_unfulfilled_dependencies(tree, raise_on_missing = true)
      return unless tree[:dependencies]
      
      tree[:dependencies].each do |package, dependency|
        dependency[:versions].select! do |version, version_subtree|
          remove_unfulfilled_dependencies(version_subtree, false)
          valid = true
          version_subtree[:dependencies].each do |k, v|
            valid = false if v[:versions].empty?
          end
          valid
        end
        raise if dependency[:versions].empty? && raise_on_missing
      end
    end
  end
end