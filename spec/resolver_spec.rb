require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe Lypack::Resolver do
  it "returns an empty dependency array for an empty tree" do
    tree = {
      dependencies: {
      }
    }

    resolver = Lypack::Resolver.new(nil)
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
    
    resolver = Lypack::Resolver.new(nil)
    deps = resolver.resolve_tree(tree)
    expect(deps).to eq(['a@0.1', 'b@0.2', 'c@0.1'])
  end
  
  it "correctly selects higher versions from multiple options" do
    select = lambda do |o| 
      resolver = Lypack::Resolver.new(nil)
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

  it "Lists all available packages" do
    with_package_setup(:simple) do
      resolver = Lypack::Resolver.new(nil)
      o = resolver.available_packages({})
      expect(o.keys).to eq(%w{a@0.1 a@0.2 b@0.1 b@0.2 b@0.2.2 c@0.1 c@0.3})
    end
  end
  
  it "Lists available packages matching a package reference" do
    with_package_setup(:simple) do
      resolver = Lypack::Resolver.new(nil)
      o = resolver.find_matching_packages('b', {})
      expect(o.keys).to eq(%w{b@0.1 b@0.2 b@0.2.2})

      o = resolver.find_matching_packages('a@0.1', {})
      expect(o.keys).to eq(%w{a@0.1})

      o = resolver.find_matching_packages('a@>=0.1', {})
      expect(o.keys).to eq(%w{a@0.1 a@0.2})

      o = resolver.find_matching_packages('b@~>0.1.0', {})
      expect(o.keys).to eq(%w{b@0.1})

      o = resolver.find_matching_packages('b@~>0.2.0', {})
      expect(o.keys).to eq(%w{b@0.2 b@0.2.2})

      o = resolver.find_matching_packages('c@~>0.1.0', {})
      expect(o.keys).to eq(%w{c@0.1})
      
      o = resolver.find_matching_packages('c@>=0.2', {})
      expect(o.keys).to eq(%w{c@0.3})
    end
  end
  
  it "Returns a prepared hash of dependencies for a package reference" do
    with_package_setup(:simple) do
      o = {}
      resolver = Lypack::Resolver.new(nil)
      resolver.find_package_versions('b@>=0.2', o, o)
      
      expect(o[:dependencies]).to eq({
        'b' => {
          clause: 'b@>=0.2',
          versions: {
            'b@0.2' => {
              path: File.expand_path('spec/setups/simple/b@0.2/package.ly'),
              dependencies: {}
            },
            'b@0.2.2' => {
              path: File.expand_path('spec/setups/simple/b@0.2.2/package.ly'),
              dependencies: {}
            }
          }
        }
      })
    end
  end
  
  it "Processes a user's file and resolves all its dependencies" do
    with_package_setup(:simple) do
      resolver = Lypack::Resolver.new('spec/user_files/simple.ly')
      o = resolver.process
      expect(o[:dependencies].keys).to eq(%w{a c})

      expect(o[:dependencies]['a'][:versions].keys).to eq(%w{a@0.1 a@0.2})
      expect(o[:dependencies]['c'][:versions].keys).to eq(%w{c@0.1})

      expect(o[:dependencies]['a'][:versions]['a@0.1'][:dependencies].keys).to eq(%w{b})

      expect(o[:dependencies]['a'][:versions]['a@0.1'][:dependencies]['b'][:versions].keys).to eq(%w{b@0.1 b@0.2 b@0.2.2})
      
      r = resolver.resolve_tree(o)
      expect(r).to eq(%w{a@0.1 b@0.1 c@0.1})
    end
  end

  it "Correctly resolves a circular dependency" do
    with_package_setup(:circular) do
      resolver = Lypack::Resolver.new('spec/user_files/circular.ly')
      
      r = resolver.resolve_package_dependencies
      expect(r).to eq(%w{a@0.1 b@0.2 c@0.3})
    end
  end
end


