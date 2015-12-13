require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe Lypack::Resolver do
  it "returns an empty dependency array for an empty tree" do
    tree = {
      dependencies: {
      }
    }

    deps = Lypack::Resolver.resolve(tree)
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
    
    deps = Lypack::Resolver.resolve(tree)
    expect(deps).to eq(['a@0.1', 'b@0.2', 'c@0.1'])
  end
  
  it "correctly selects higher versions from multiple options" do
    select = lambda {|o| Lypack::Resolver.select_highest_versioned_permutation(o, [])}
    
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
end

