class Lypack::Resolver
  def initialize(user_file)
    @user_file = user_file
  end
  
  # Resolving package dependencies involves two stages:
  # 1. Create a dependency tree from user files and packages
  # 2. Resolve the dependency tree into a list of specific package versions
  def resolve_package_dependencies
    tree = get_dependency_tree
    resolve_tree(tree)
  end
  
  DEP_RE = /\\(require|include) "([^"]+)"/.freeze
  INCLUDE = "include".freeze
  REQUIRE = "require".freeze
  
  # Each "leaf" on the dependency tree is a hash of the following structure:
  # {
  #   dependencies: {
  #     "<package_name>" => {
  #       clause: "<package>@<version_specifier>",
  #       versions: {
  #         "<version>" => {...}
  #         ...
  #       }
  #     }
  #   }
  # }
  #
  # Since files to be processed are added to a queue, this method loops through
  # the queue until it's empty.
  def get_dependency_tree
    tree = {
      dependencies: {},
      queue: [],
      processed_files: {}
    }
    
    queue_file_for_processing(@user_file, tree, tree)

    while job = pull_file_from_queue(tree)
      process_lilypond_file(job[:path], tree, job[:leaf])
    end
    
    remove_unfulfilled_dependencies(tree)
    
    tree
  end
  
  # Scans a lilypond file for \require and \include statements. An included
  # file is queued for processing. For required packages, search for suitable
  # versions of the package and add them to the tree.
  #
  # The leaf argument is a pointer to the current leaf on the tree on which to
  # add dependencies. This is how transitive dependencies are represented.
  def process_lilypond_file(path, tree, leaf)
    # path is expected to be absolute
    return if tree[:processed_files][path]
    
    ly_content = IO.read(path)
    dir = File.dirname(path)
    
    # Parse lilypond file for \include and \require
    ly_content.scan(DEP_RE) do |type, path|
      case type
      when INCLUDE
        qualified_path = File.expand_path(path, dir)
        queue_file_for_processing(qualified_path, tree, leaf)
      when REQUIRE
        find_package_versions(path, tree, leaf)
      end
    end
    
    tree[:processed_files][path] = true
  end
  
  def queue_file_for_processing(path, tree, leaf)
    (tree[:queue] ||= []) << {path: path, leaf: leaf}
  end
  
  def pull_file_from_queue(tree)
    tree[:queue].shift
  end
  
  # A package specifier is of the form <package>@<version specifier>, where
  # the version specifier can be simply a version number, or include an operator
  # before the version number. Accepted operators: >=, ~>
  PACKAGE_RE = /^([^@]+)(?:@(.+))?$/
  
  # Find available packaging matching the package specifier, and queue them for
  # processing any include files or transitive dependencies.
  def find_package_versions(ref, tree, leaf)
    return {} unless ref =~ PACKAGE_RE
    ref_package = $1
    version_clause = $2

    matches = find_matching_packages(ref, tree)
    
    # Raise if no match found and we're at top of the tree
    if matches.empty? && (tree == leaf)
      raise "No package found for requirement #{ref}"
    end
    
    matches.each do |p, subtree|
      if subtree[:path]
        queue_file_for_processing(subtree[:path], tree, subtree)
      end
    end

    # Setup up dependency leaf
    (leaf[:dependencies] ||= {}).merge!({
      ref_package => {
        clause: ref,
        versions: matches
      }
    })
  end
  
  # Find packages meeting the version requirement
  def find_matching_packages(req, tree)
    return {} unless req =~ PACKAGE_RE
    
    req_package = $1
    req_version = $2
    req = Gem::Requirement.new(req_version || '>=0')

    available_packages(tree).select do |package, sub_tree|
      if package =~ PACKAGE_RE
        version = Gem::Version.new($2 || '0')
        (req_package == $1) && (req =~ version)
      else
        nil
      end
    end
  end
  
  MAIN_PACKAGE_FILE = 'package.ly'
  
  # Memoize and return a hash of available packages
  def available_packages(tree)
    tree[:available_packages] ||= get_available_packages(Lypack.packages_dir)
  end
  
  # Return a hash of all packages found in the packages directory, creating a
  # leaf for each package
  def get_available_packages(dir)
    Dir["#{Lypack.packages_dir}/*"].inject({}) do |m, p|
      m[File.basename(p)] = {
        path: File.join(p, MAIN_PACKAGE_FILE), 
        dependencies: {},
        
      }
      m
    end
  end

  # Recursively remove any dependency for which no version is locally 
  # available. If no version is found for any of the dependencies specified
  # by the user, an error is raised.
  # 
  # The processed hash is used for keeping track of dependencies that were
  # already processed, and thus deal with circular dependencies.
  def remove_unfulfilled_dependencies(tree, raise_on_missing = true, processed = {})
    return unless tree[:dependencies]
    
    tree[:dependencies].each do |package, dependency|
      dependency[:versions].select! do |version, version_subtree|
        if processed[version]
          true
        else
          processed[version] = true

          # Remove unfulfilled transitive dependencies
          remove_unfulfilled_dependencies(version_subtree, false, processed)
          valid = true
          version_subtree[:dependencies].each do |k, v|
            valid = false if v[:versions].empty?
          end
          valid
        end
      end
      if dependency[:versions].empty? && raise_on_missing
        raise "No valid version found for package #{package}"
      end
    end
  end
  
  # Resolve the given dependency tree and return a list of concrete packages
  # that meet all dependency requirements.
  #
  # The following stages are involved:
  # - Create permutations of possible version combinations for all dependencies
  # - Remove invalid permutations
  # - Select the permutation with the highest versions
  def resolve_tree(tree)
    permutations = permutate_simplified_tree(tree)
    permutations = filter_invalid_permutations(permutations)

    user_deps = tree[:dependencies].keys
    result = select_highest_versioned_permutation(permutations, user_deps).flatten
    
    if result.empty? && !tree[:dependencies].empty?
      raise "Failed to satisfy dependency requirements"
    else
      result
    end
  end
  
  # Create permutations of package versions for the given dependency tree. The
  # tree is first simplified (superfluous information removed), then turned into
  # an array of dependencies, from which version permutations are generated.
  def permutate_simplified_tree(tree)
    deps = dependencies_array(simplified_deps_tree(tree))
    return deps if deps.empty?

    # Return a cartesian product of dependencies
    deps[0].product(*deps[1..-1]).map(&:flatten)
  end
  
  # Converts a simplified dependency tree into an array of dependencies, 
  # containing a sub-array for each top-level dependency. Each such sub-array
  # contains, in its turn, version permutations for the top-level dependency
  # and any transitive dependencies.
  def dependencies_array(tree, processed = {})
    return processed[tree] if processed[tree]

    deps_array = []
    processed[tree] = deps_array
    
    tree.each do |pack, versions|
      a = []
      versions.each do |version, deps|
        perms = []
        sub_perms = dependencies_array(deps, processed)
        if sub_perms == []
          perms += [version]
        else
          sub_perms[0].each do |perm|
            perms << [version] + [perm].flatten
          end
        end
        a += perms
      end
      deps_array << a
    end

    deps_array
  end
  
  # Converts the dependency tree into a simplified dependency tree of the form
  # {
  #   <package name> =>
  #     <version> => 
  #       <package name> =>
  #         <version> => ...
  #         ...
  #       ...
  #     ...
  #   ...
  # }
  # The processed hash is used to deal with circular dependencies
  def simplified_deps_tree(version, processed = {})
    return {} unless version[:dependencies]
    
    return processed[version] if processed[version]
    processed[version] = dep_versions = {}

    # For each dependency, generate a deps tree for each available version
    version[:dependencies].each do |p, subtree|
      dep_versions[p] = {}
      subtree[:versions].each do |v, version_subtree|
        dep_versions[p][v] = 
          simplified_deps_tree(version_subtree, processed)
      end
    end

    dep_versions
  end
  
  # Remove invalid permutations, that is permutations that contain multiple
  # versions of the same package, a scenario which could arrive in the case of
  # circular dependencies, or when different dependencies rely on different
  # versions of the same transitive dependency.
  def filter_invalid_permutations(permutations)
    valid = []
    permutations.each do |perm|
      versions = {}; invalid = false
      perm.each do |ref|
        if ref =~ /(.+)@(.+)/
          name, version = $1, $2
          if versions[name] && versions[name] != version
            invalid = true
            break
          else
            versions[name] = version
          end
        end
      end
      valid << perm.uniq unless invalid
    end

    valid
  end
  
  # Select the highest versioned permutation of package versions
  def select_highest_versioned_permutation(permutations, user_deps)
    sorted = sort_permutations(permutations, user_deps)
    sorted.empty? ? [] : sorted.last
  end

  # Sort permutations by version numbers
  def sort_permutations(permutations, user_deps)
    map = lambda do |m, p|
      if p =~ PACKAGE_RE
        m[$1] = Gem::Version.new($2 || '0.0')
      end
      m
    end
    
    compare = lambda do |x, y|
      x_versions = x.inject({}, &map)
      y_versions = y.inject({}, &map)
      
      # Naive implementation - add up the comparison scores for each package
      x_versions.keys.inject(0) do |s, k|
        cmp = x_versions[k] <=> y_versions[k]
        s += cmp unless cmp.nil?
        s
      end
    end
    
    permutations.sort(&compare)
  end  
end
  
