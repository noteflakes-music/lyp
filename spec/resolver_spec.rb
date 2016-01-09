require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe Lyp::Resolver do
  it "returns an empty dependency array for an empty tree" do
    tree = {
      dependencies: {
      }
    }

    resolver = Lyp::Resolver.new(nil)
    deps = resolver.resolve_tree(tree)
    expect(deps).to eq([])
  end
  
  it "correctly resolves versions for a dependency tree" do
    tree = {
      dependencies: {
        "a" => {
          clause: "a@>=0.1",
          versions: {
            "a@0.1" => {
              dependencies: {
                "b" => {
                  clause: "b@>=0.2.0",
                  versions: {
                    "b@0.2" => {},
                    "b@0.3" => {}
                  }
                }
              }
            },
            "a@0.2" => {
              dependencies: {
                "b" => {
                  clause: "b@~>0.3.0",
                  versions: {
                    "b@0.3" => {}
                  }
                }
              }
            }
          }
        },
        "c" => {
          clause: "c@~>0.1.0",
          versions: {
            "c@0.1" => {
              dependencies: {
                "b" => {
                  clause: "b@~>0.2.0",
                  versions: {
                    "b@0.2" => {}
                  }
                }
              }
            }
          }
        }
      }
    }
    
    resolver = Lyp::Resolver.new(nil)
    deps = resolver.resolve_tree(tree)
    expect(deps).to eq(['a@0.1', 'b@0.2', 'c@0.1'])
  end
  
  it "correctly selects higher versions from multiple options" do
    select = lambda do |o| 
      resolver = Lyp::Resolver.new(nil)
      resolver.select_highest_versioned_permutation(o, [])
    end
    
    opts = [
      ['a@0.1'], ['a@0.1.1']
    ]
    expect(select[opts]).to eq(['a@0.1.1'])

    opts = [
      ['a@0.1'], ['a']
    ]
    expect(select[opts]).to eq(['a@0.1'])
    
    opts = [
      ['a@0.1', 'c@0.2'], ['a@0.2', 'c@0.1']
    ]
    # In this case the result can be considered arbitrary, it depends on the 
    # order of permutations in the input array
    expect(select[opts]).to eq(['a@0.2', 'c@0.1'])
    
    opts = [
      ['a@0.1', 'b@0.2', 'c@0.1'], ['a@0.1', 'b@0.2.3', 'c@0.1']
    ]
    expect(select[opts]).to eq(['a@0.1', 'b@0.2.3', 'c@0.1'])
    
  end

  it "lists all available packages" do
    with_packages(:simple) do
      resolver = Lyp::Resolver.new(nil)
      o = resolver.available_packages({})
      expect(o.keys.sort).to eq(%w{a@0.1 a@0.2 b@0.1 b@0.2 b@0.2.2 c@0.1 c@0.3})
    end
  end
  
  it "lists available packages matching a package reference" do
    with_packages(:simple) do
      resolver = Lyp::Resolver.new(nil)
      o = resolver.find_matching_packages('b', {})
      expect(o.keys.sort).to eq(%w{b@0.1 b@0.2 b@0.2.2})

      o = resolver.find_matching_packages('a@0.1', {})
      expect(o.keys).to eq(%w{a@0.1})

      o = resolver.find_matching_packages('a@>=0.1', {})
      expect(o.keys.sort).to eq(%w{a@0.1 a@0.2})

      o = resolver.find_matching_packages('b@~>0.1.0', {})
      expect(o.keys).to eq(%w{b@0.1})

      o = resolver.find_matching_packages('b@~>0.2.0', {})
      expect(o.keys.sort).to eq(%w{b@0.2 b@0.2.2})

      o = resolver.find_matching_packages('c@~>0.1.0', {})
      expect(o.keys).to eq(%w{c@0.1})
      
      o = resolver.find_matching_packages('c@>=0.2', {})
      expect(o.keys).to eq(%w{c@0.3})
    end
  end
  
  it "returns a prepared hash of dependencies for a package reference" do
    with_packages(:simple) do
      o = {}
      resolver = Lyp::Resolver.new(nil)
      resolver.find_package_versions('b@>=0.2', o, o, {})
      
      expect(o[:dependencies]).to eq({
        'b' => {
          clause: 'b@>=0.2',
          versions: {
            'b@0.2' => {
              path: "#{$packages_dir}/b@0.2/package.ly",
              dependencies: {}
            },
            'b@0.2.2' => {
              path: "#{$packages_dir}/b@0.2.2/package.ly",
              dependencies: {}
            }
          }
        }
      })
    end
  end
  
  it "processes a user's file and resolves all its dependencies" do
    with_packages(:simple) do
      resolver = Lyp::Resolver.new('spec/user_files/simple.ly')
      o = resolver.get_dependency_tree
      expect(o[:dependencies].keys).to eq(%w{a c})

      expect(o[:dependencies]['a'][:versions].keys).to eq(%w{a@0.1 a@0.2})
      expect(o[:dependencies]['c'][:versions].keys).to eq(%w{c@0.1})

      expect(o[:dependencies]['a'][:versions]['a@0.1'][:dependencies].keys).to eq(%w{b})

      expect(o[:dependencies]['a'][:versions]['a@0.1'][:dependencies]['b'][:versions].keys.sort).to eq(%w{b@0.1 b@0.2 b@0.2.2})
      
      r = resolver.resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.1 c@0.1})
      expect(r[:package_paths].keys.sort).to eq(
        ["a", "b@>=0.1.0", "b@~>0.1.0", "b@~>0.2.0", "c"]
      )
      expect(r[:package_paths]["a"]).to eq(
        "#{$packages_dir}/a@0.1/package.ly"
      )
      expect(r[:package_paths]["b@>=0.1.0"]).to eq(
        "#{$packages_dir}/b@0.1/package.ly"
      )
      expect(r[:package_paths]["b@~>0.1.0"]).to eq(
        "#{$packages_dir}/b@0.1/package.ly"
      )
      expect(r[:package_paths]["b@~>0.2.0"]).to eq(
        "#{$packages_dir}/b@0.1/package.ly"
      )
      expect(r[:package_paths]["c"]).to eq(
        "#{$packages_dir}/c@0.1/package.ly"
      )
    end
  end

  it "correctly resolves a circular dependency" do
    with_packages(:circular) do
      resolver = Lyp::Resolver.new('spec/user_files/circular.ly')

      r = resolver.resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.2 c@0.3})
    end
  end

  it "correctly resolves a transitive dependency" do
    with_packages(:transitive) do
      resolver = Lyp::Resolver.new('spec/user_files/circular.ly')

      r = resolver.resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.2 c@0.3})
    end
  end

  it "correctly resolves dependencies with include files" do
    with_packages(:includes) do
      resolver = Lyp::Resolver.new('spec/user_files/circular.ly')

      r = resolver.resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.2 c@0.3})
    end
  end

  it "returns no dependencies for file with no requires" do
    with_packages(:simple) do
      resolver = Lyp::Resolver.new('spec/user_files/no_require.ly')

      r = resolver.resolve_package_dependencies
      expect(r[:definite_versions]).to eq([])
    end
  end

  it "raises error on an unavailable dependency" do
    with_packages(:simple) do
      resolver = Lyp::Resolver.new('spec/user_files/not_found.ly')

      expect {resolver.resolve_package_dependencies}.to raise_error
    end
  end

  it "raises error on an invalid circular dependency" do
    with_packages(:circular_invalid) do
      resolver = Lyp::Resolver.new('spec/user_files/circular.ly')
      # here it should not raise, since a@0.2 satisfies the dependency
      # requirements
      expect(resolver.resolve_package_dependencies[:definite_versions]).to eq(
        ["a@0.2", "b@0.2", "c@0.3"]
      )

      # When the user specifies a@0.1, we should raise!
      resolver = Lyp::Resolver.new('spec/user_files/circular_invalid.ly')
      expect {resolver.resolve_package_dependencies}.to raise_error
    end
  end

  it "handles requires in include files" do
    with_packages(:simple) do
      resolver = Lyp::Resolver.new('spec/user_files/include1.ly')

      r = resolver.resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.1 c@0.1})
    end
  end

  it "handles a big package setup" do
    with_packages(:big) do
      resolver = Lyp::Resolver.new('spec/user_files/simple.ly')

      r = resolver.resolve_package_dependencies
      expect(r[:definite_versions].sort).to eq(
        %w{a@0.3.2 b@0.3.2 c@0.3.2 d@0.3.2 e@0.3.2 f@0.2.1 g@0.3.2 h@0.3.2 i@0.3.2 j@0.3.2}
      )
    end
  end

  it "raises error for missing file" do
    with_packages(:big) do
      resolver = Lyp::Resolver.new('spec/user_files/does_not_exist.ly')
      
      expect do
        resolver.resolve_package_dependencies
      end.to raise_error
    end
  end

end


