module Lyp
  class DependencySpec
    attr_reader :clause, :versions, :location

    def initialize(clause, versions, location = nil)
      @clause = clause
      @versions = versions.inject({}) {|m, kv| m[kv[0].to_s] = kv[1]; m}
      @location = location
    end

    def add_version(version, leaf)
      @versions[version.to_s] = leaf
    end

    def eql?(o)
      @clause.eql?(o.clause) && @versions.eql?(o.versions)
    end

    def hash
      {clause: clause, versions: versions}.hash
    end
  end

  class DependencyLeaf
    attr_reader :dependencies

    def initialize(dependencies = {})
      @dependencies = dependencies.inject({}) {|m, kv| m[kv[0].to_s] = kv[1]; m}
    end

    def add_dependency(name, spec)
      if @dependencies[name.to_s] && !spec.eql?(@dependencies[name.to_s])
        DependencyResolver.error("Clause mismatch found in %s", spec.location)
      end
      @dependencies[name.to_s] = spec
    end

    def resolve(opts = {})
      DependencyResolver.new(self, opts).resolve_tree
    end

    def eql?(o)
      @dependencies.eql?(o.dependencies)
    end

    def hash
      @dependencies.hash
    end
  end

  class DependencyPackage < DependencyLeaf
    attr_reader :path

    def initialize(path, dependencies = {})
      @path = path
      super(dependencies)
    end
  end

  class DependencyResolver
    attr_reader :tree, :opts

    def initialize(tree, opts = {})
      if tree.is_a?(String)
        @user_file = tree
        @tree = DependencyLeaf.new
      else
        @tree = tree
      end
      @opts = opts
      @ext_require = @opts[:ext_require]
      @queue = []
      @processed_files = {}
    end

    # Resolving package dependencies involves two stages:
    # 1. Create a dependency tree from user files and packages
    # 2. Resolve the dependency tree into a list of specific package versions
    def resolve_package_dependencies
      compile_dependency_tree
      definite_versions = resolve_tree
      specifier_map = map_specifiers_to_versions

      refs, dirs = {}, {}
      definite_versions.each do |v|
        package = v =~ Lyp::PACKAGE_RE && $1

        specifier_map[package].each_key {|s| refs[s] = package}
        dirs[package] = File.dirname(available_packages[v].path)
      end

      {
        user_file: @user_file,
        definite_versions: definite_versions,
        package_refs: refs,
        package_dirs: dirs,
        preload: @opts[:ext_require]
      }
    end

    # Resolve the given dependency tree and return a list of concrete packages
    # that meet all dependency requirements.
    #
    # The following stages are involved:
    # - Create permutations of possible version combinations for all dependencies
    # - Remove invalid permutations
    # - Select the permutation with the highest versions
    def resolve_tree
      permutations = permutate_simplified_tree
      permutations = filter_invalid_permutations(permutations)

      # select highest versioned dependencies (for those specified by user)
      user_deps = tree.dependencies.keys
      result = select_highest_versioned_permutation(permutations, user_deps).flatten

      if result.empty? && !tree.dependencies.empty?
        error("Failed to satisfy dependency requirements")
      else
        result
      end
    end

    # DEP_RE = /\\((?:lyp[\-\:]require)|lyp-load|lyp-include|require|include|pinclude|pincludeOnce)\s+(?:"|#')?([^\s"\)]+)"?/.freeze
    DEP_RE = /\\(lyp-require|lyp-load|lyp-include|require|include|pinclude|pincludeOnce)\s+(?:"|#')?([^\s"]+)"?/.freeze
    LYP_REQUIRE = "lyp-require".freeze
    LYP_INCLUDE = "lyp-include".freeze
    LYP_LOAD    = "lyp-load".freeze
    INCLUDE = "include".freeze
    PINCLUDE = "pinclude".freeze
    PINCLUDE_ONCE = "pincludeOnce".freeze
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
    def compile_dependency_tree(opts = {})
      old_opts = @opts
      @opts = @opts.merge(opts)
      @queue = []
      @processed_files = {}
      @tree ||= DependencyLeaf.new

      queue_file_for_processing(@user_file, @tree)

      while job = pull_file_from_queue
        process_lilypond_file(job[:path], job[:leaf], opts)
      end

      unless @opts[:ignore_missing]
        squash_old_versions
        remove_unfulfilled_dependencies(tree)
      end

      @tree
    ensure
      @opts = old_opts
    end

    # Scans a lilypond file for \require and \(p)include statements. An included
    # file is queued for processing. For required packages, search for suitable
    # versions of the package and add them to the tree.
    #
    # The leaf argument is a pointer to the current leaf on the tree on which to
    # add dependencies. This is how transitive dependencies are represented.
    def process_lilypond_file(path, leaf, opts)
      # path is expected to be absolute
      return if @processed_files[path]

      ly_content = IO.read(path)
      dir = File.dirname(path)

      # Parse lilypond file for \include and \require
      location = {path: path, line: 0}
      ly_content.each_line do |line|
        location[:line] += 1
        line.scan(DEP_RE) do |type, ref|
          case type
          when LYP_INCLUDE, LYP_LOAD, INCLUDE, PINCLUDE, PINCLUDE_ONCE
            process_include_command(ref, dir, leaf, opts, location)
          when LYP_REQUIRE, REQUIRE
            process_require_command(ref, dir, leaf, opts, location)
          end
        end
      end

      # process any external requires (supplied using the -r command line option)
      if @ext_require
        @ext_require.each do |p|
          process_require_command(p, dir, leaf, opts, {ext_require: true})
        end
        @ext_require = nil
      end

      @processed_files[path] = true
    rescue Errno::ENOENT
      error("Could not find file #{path}")
    end

    def process_include_command(ref, dir, leaf, opts, location)
      # a package would normally use a plain \pinclude or \pincludeOnce
      # command to include package files, e.g. \pinclude "inc/init.ly".
      #
      # But a package can also qualify the file reference with the package
      # name, in order to be able to load files after the package has already
      # been loaded, e.g. \pinclude "mypack:inc/init.ly"
      if ref =~ /^([^\:]+)\:(.+)$/
        # ignore null package (used for testing purposes only)
        return if $1 == 'null'
        ref = $2
      end

      full_path = find_include_file(ref, dir, location)
      queue_file_for_processing(full_path, leaf)
    end

    def find_include_file(ref, dir, location)
      search_paths = [dir]
      search_paths += @opts[:include_paths] if @opts[:include_paths]

      # Reminder: return inside a proc returns from the caller
      search = proc {|fn| return fn if File.file?(fn) }

      search_paths.each do |path|
        full_path = File.expand_path(ref, path)
        search.(full_path)
        search.("#{full_path}.ily")
        search.("#{full_path}.ly")
      end

      error("Could not find include file reference #{ref} specified in %s", location)
    end

    def process_require_command(ref, dir, leaf, opts, location)
      forced_path = nil
      if ref =~ /^([^\:]+)\:(.+)$/
        ref = $1
        forced_path = File.expand_path($2, dir)
      end

      ref =~ Lyp::PACKAGE_RE
      package, version = $1, $2
      return if package == 'null'

      # set forced path if applicable
      if forced_path
        set_forced_package_path(package, forced_path)
      end

      find_package_versions(ref, leaf, location)
    end

    def queue_file_for_processing(path, leaf)
      @queue << {path: path, leaf: leaf}
    end

    def pull_file_from_queue
      @queue.shift
    end

    # Create permutations of package versions for the given dependency tree. The
    # tree is first simplified (superfluous information removed), then turned into
    # an array of dependencies, from which version permutations are generated.
    def permutate_simplified_tree
      deps = dependencies_array(simplified_deps_tree(tree))
      return deps if deps.empty?

      # Return a cartesian product of dependencies
      deps[0].product(*deps[1..-1]).map(&:flatten)
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
    def simplified_deps_tree(leaf, processed = {})
      return {} unless leaf.dependencies

      return processed[leaf] if processed[leaf]
      processed[leaf] = dep_versions = {}

      # For each dependency, generate a deps tree for each available version
      leaf.dependencies.each do |p, spec|
        dep_versions[p] = {}
        spec.versions.each do |v, subleaf|
          dep_versions[p][v] =
            simplified_deps_tree(subleaf, processed)
        end
      end

      dep_versions
    end

    # Converts a simplified dependency tree into an array of dependencies,
    # containing a sub-array for each top-level dependency. Each such sub-array
    # contains, in its turn, version permutations for the top-level dependency
    # and any transitive dependencies.
    def dependencies_array(leaf, processed = {})
      return processed[leaf] if processed[leaf]

      deps_array = []
      processed[leaf] = deps_array

      leaf.each do |pack, versions|
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
      # Cache for versions converted to Gem::Version instances
      versions = {}

      map = lambda do |m, p|
        if p =~ Lyp::PACKAGE_RE
          m[$1] = versions[p] ||= (Lyp.version($2 || '0.0') rescue nil)
        end
        m
      end

      compare = lambda do |x, y|
        x_versions = x.inject({}, &map)
        y_versions = y.inject({}, &map)

        # If the dependency is direct (not transitive), just compare its versions.
        # Otherwise, add the result of comparison to score.
        x_versions.inject(0) do |score, kv|
          package = kv[0]
          cmp = kv[1] <=> y_versions[package]
          if user_deps.include?(package) && cmp != 0
            return cmp
          else
            score += cmp unless cmp.nil?
          end
          score
        end
      end

      permutations.sort(&compare)
    end

    # Memoize and return a hash of available packages
    def available_packages
      @available_packages ||= get_available_packages(Lyp.packages_dir)
    end

    MAIN_PACKAGE_FILE = 'package.ly'

    # Return a hash of all packages found in the packages directory, creating a
    # leaf for each package
    def get_available_packages(dir)
      packages = Dir["#{Lyp.packages_dir}/**/*"].inject({}) do |m, p|
        entry_point_path = File.join(p, MAIN_PACKAGE_FILE)
        if File.file?(entry_point_path)
          package_name = p.gsub(/^#{Lyp.packages_dir}\//, '')
          m[package_name] = DependencyPackage.new(entry_point_path)
        end
        m
      end

      forced_paths = @opts[:forced_package_paths] || {}

      if @opts[:forced_package_paths]
        @opts[:forced_package_paths].each do |package, path|
          packages["#{package}@forced"] = DependencyPackage.new(File.join(path, MAIN_PACKAGE_FILE))
        end
      end

      packages
    end

    # Find packages meeting the version requirement
    def find_matching_packages(req)
      return {} unless req =~ Lyp::PACKAGE_RE

      req_package = $1
      req_version = $2

      req = nil
      if @opts[:forced_package_paths] && @opts[:forced_package_paths][req_package]
        req_version = 'forced'
      end

      req = Lyp.version_req(req_version || '>=0') rescue nil
      available_packages.select do |package, leaf|
        if (package =~ Lyp::PACKAGE_RE) && (req_package == $1)
          version = Lyp.version($2 || '0') rescue nil
          if version.nil? || req.nil?
            req_version.nil? || (req_version == $2)
          else
            req =~ version
          end
        else
          nil
        end
      end
    end

    # Find available packaging matching the package specifier, and queue them for
    # processing any include files or transitive dependencies.
    def find_package_versions(ref, leaf, location)
      return {} unless ref =~ Lyp::PACKAGE_RE
      ref_package = $1
      version_clause = $2

      matches = find_matching_packages(ref)

      # Raise if no match found and we're at top of the tree
      if matches.empty? && (leaf == tree) && !opts[:ignore_missing]
        msg = "Missing package dependency #{ref} in %sYou can install any missing packages by running:\n\n  lyp resolve #{@user_file}"
        error(msg, location)
      end

      matches.each do |p, package_leaf|
        if package_leaf.path
          queue_file_for_processing(package_leaf.path, package_leaf)
        end
      end

      # Setup up dependency leaf
      leaf.add_dependency(ref_package, DependencySpec.new(ref, matches, location))
    end

    # Remove redundant older versions of dependencies by collating package
    # versions by package specifiers, then removing older versions for any
    # package for which a single package specifier exists.
    def squash_old_versions
      specifiers = map_specifiers_to_versions

      compare_versions = lambda do |x, y|
        v_x = x =~ Lyp::PACKAGE_RE && Lyp.version($2)
        v_y = y =~ Lyp::PACKAGE_RE && Lyp.version($2)
        x <=> y
      end

      specifiers.each do |package, clauses|
        # Remove old versions only if the package is referenced using a single
        # specifier clause
        next unless clauses.size == 1

        specs = clauses.values.first
        specs.each do |s|
          if s.versions.values.uniq.size == 1
            versions = s.versions.keys.sort(&compare_versions)
            latest = versions.last
            s.versions.select! {|k, v| k == latest}
          end
        end
      end
    end

    # Return a hash mapping packages to package specifiers to spec objects, to
    # be used to eliminate older versions from the dependency tree
    def map_specifiers_to_versions
      specifiers = {}
      processed = {}

      l = lambda do |t|
        return if processed[t.object_id]
        processed[t.object_id] = true
        t.dependencies.each do |package, spec|
          specifiers[package] ||= {}
          specifiers[package][spec.clause] ||= []
          specifiers[package][spec.clause] << spec
          spec.versions.each_value {|v| l[v]}
        end
      end

      l[@tree]
      specifiers
    end

    # Recursively remove any dependency for which no version is locally
    # available. If no version is found for any of the dependencies specified
    # by the user, an error is raised.
    #
    # The processed hash is used for keeping track of dependencies that were
    # already processed, and thus deal with circular dependencies.
    def remove_unfulfilled_dependencies(leaf, raise_on_missing = true, processed = {})
      tree.dependencies.each do |package, dependency|
        dependency.versions.select! do |version, leaf|
          if processed[version]
            true
          else
            processed[version] = true

            # Remove unfulfilled transitive dependencies
            remove_unfulfilled_dependencies(leaf, false, processed)
            valid = true
            leaf.dependencies.each do |k, v|
              valid = false if v.versions.empty?
            end
            valid
          end
        end
        if dependency.versions.empty? && raise_on_missing
          error("No valid version found for package #{package}")
        end
      end
    end

    def set_forced_package_path(package, path)
      @opts[:forced_package_paths] ||= {}
      @opts[:forced_package_paths][package] = path

      available_packages["#{package}@forced"] = DependencyPackage.new(
        File.join(path, MAIN_PACKAGE_FILE))
    end

    def error(msg, location = nil)
      DependencyResolver.error(msg, location)
    end

    def self.error(msg, location = nil)
      location = location ? format_location(location) : nil
      raise ResolveError, msg % location
    end

    def self.format_location(location)
      return "" unless location
      return "require flag" if location[:ext_require]
      source_line = get_source_line(location[:path], location[:line])
      "#{location[:path]}:#{location[:line]}: \n\n  #{source_line}\n"
    end

    def self.get_source_line(path, line)
      IO.read(path).lines[line - 1]
    rescue => e
      "???"
    end
  end
end

class ResolveError < RuntimeError
end
