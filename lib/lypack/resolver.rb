module Lypack::Resolver
  class << self
    def resolve(tree)
      permutations = permutate_simplified_tree(tree)
      permutations = filter_invalid_permutations(permutations)

      user_deps = tree[:dependencies].keys
      select_highest_versioned_permutation(permutations, user_deps)
    end
    
    def verify_version_availability(tree)
      return unless tree[:dependencies]
      
      tree[:dependencies].select! do |k, subtree|
        if subtree[:versions]
          subtree[:versions].each do |v, vsubtree|
            remove_unfulfilled_dependency_versions(vsubtree, false)
          end
          !subtree[:versions].empty?
        end
      end
    end
    
    def remove_unfulfilled_dependency_versions(tree, raise_on_missing_versions = true)
      return unless tree[:dependencies]
      
      tree[:dependencies].select! do |k, subtree|
        if subtree[:versions]
          subtree[:versions].each do |v, vsubtree|
            remove_unfulfilled_dependency_versions(vsubtree, false)
          end
          true
        else
          raise if raise_on_missing_versions
          false
        end
      end
    end
    
    def permutate_simplified_tree(tree)
      deps = dependencies_array(simplified_deps_tree(tree))
      return deps if deps.size < 2
  
      # Return a cartesian product of dependencies
      deps[0].product(*deps[1..-1]).map(&:flatten)
    end
    
    def dependencies_array(tree)
      deps_array = []
      tree.each do |pack, versions|
        a = []
        versions.each do |version, deps|
          sub_perms = dependencies_array(deps)
          if sub_perms == []
            a << version
          else
            a += [version].product(*sub_perms)
          end
        end
        deps_array << a
      end
  
      deps_array
    end
    
    def simplified_deps_tree(version)
      return {} unless version[:dependencies]
  
      dep_versions = {}
  
      # For each dependency, generate a deps tree for each available version
      version[:dependencies].each do |p, opts|
        opts[:versions].each do |v, opts2|
          dep_versions[p] ||= {}
          dep_versions[p][v] = simplified_deps_tree(opts2)
        end
      end
  
      dep_versions
    end
    
    def filter_invalid_permutations(permutations)
      valid = []
      permutations.each do |p|
        versions = {}; invalid = false
        p.each do |ref|
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
        valid << p.uniq unless invalid
      end
  
      valid
    end
    
    def select_highest_versioned_permutation(permutations, user_deps)
      sorted = sort_permutations(permutations, user_deps)
      sorted.empty? ? [] : sorted.last
    end
    
    PACKAGE_REF_RE = /^([^@]+)(?:@(.+))?$/
    
    def sort_permutations(permutations, user_deps)
      map = lambda do |m, p|
        if p =~ PACKAGE_REF_RE
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
end