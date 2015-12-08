module Lypack::Loader
  class << self
    DEP_RE = /\\(require|include) "([^"]+)"/.freeze
    INCLUDE = "include".freeze
    REQUIRE = "require".freeze
    
    # Returns a lilypond file
    def process(path)
      deps_tree = {
        dependencies: {},
        queue: [],
        processed_files: {}
      }
      
      queue_file_for_processing(path, deps_tree, deps_tree)

      while job = pull_file_from_queue(deps_tree)
        process_lilypond_file(job[:path], deps_tree, job[:ptr])
      end
      
      deps_tree
    end
    
    def process_lilypond_file(path, deps_tree, deps_ptr)
      # path is expected to be absolute
      return if file_processed?(path, deps_tree)
      
      ly_content = IO.read(path)
      dir = File.dirname(path)
      
      ly_content.scan(DEP_RE) do |type, path|
        case type
        when INCLUDE
          qualified_path = File.expand_path(path, dir)
          queue_file_for_processing(qualified_path, deps_tree, deps_ptr)
        when REQUIRE
          find_package_versions(path, deps_tree, deps_hash)
        end
      end
    end
    def file_processed?(path, deps_tree)
      deps_tree[:processed_files][path]
    end
    
    def queue_file_for_processing(path, deps_tree, deps_ptr)
      deps_tree[:queue] << {path: path, ptr: deps_ptr}
    end
    
    def pull_file_from_queue(deps_tree)
      deps_tree[:queue].shift
    end
    
    PACKAGE_RE = /^([^@]+)(?:@(.+))?$/
    
    def find_package_versions(ref, deps_tree, deps_ptr)
      return unless ref =~ PACKAGE_RE
      
      ref_package = $1
      version_clause = $2
      req = Gem::Requirement.new(version_clause || '0')

      found = available_packages.select do |p, sub_tree|
        if p =~ PACKAGE_RE
          version = Gem::Version.new($2 || '0')
          (ref_package == $1) && (req =~ version)
        else
          nil
        end
      end
      
      # Make sure found packages are processed
      found.each do |p, sub_tree|
        if sub_tree[:path]
          queue_file_for_processing(sub_tree[:path], deps_tree, subtree)
        end
      end
      
      deps_ptr[:dependencies].merge!({
        ref_package => {
          clause: version_clause,
          versions: found
        }
      })
    end
    
    DEFAULT_PACKAGE_DIRECTORY = File.expand_path('~/.lypack/packages')
    MAIN_PACKAGE_FILE = 'package.ly'
    
    def available_packages(deps_tree)
      deps_tree[:available_packages] ||= 
        Dir["#{DEFAULT_PACKAGE_DIRECTORY}/*"].inject({}) do |m, p|
          m[File.basename(p)] = {
            path: File.join(p, MAIN_PACKAGE_FILE), 
            dependencies: {},
            
          }
          m
        end
    end
  end
end