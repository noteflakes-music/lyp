require File.expand_path('spec_helper', File.dirname(__FILE__))
require 'pp'

RSpec.describe Lypack::Loader do
  it "Lists all available packages" do
    with_package_setup(:simple) do
      o = Lypack::Loader.available_packages({})
      expect(o.keys).to eq(%w{a@0.1 a@0.2 b@0.1 b@0.2 b@0.2.2 c@0.1 c@0.3})
    end
  end
  
  it "Lists available packages matching a package reference" do
    with_package_setup(:simple) do
      o = Lypack::Loader.find_matching_packages('b', {})
      expect(o.keys).to eq(%w{b@0.1 b@0.2 b@0.2.2})

      o = Lypack::Loader.find_matching_packages('a@0.1', {})
      expect(o.keys).to eq(%w{a@0.1})

      o = Lypack::Loader.find_matching_packages('a@>=0.1', {})
      expect(o.keys).to eq(%w{a@0.1 a@0.2})

      o = Lypack::Loader.find_matching_packages('b@~>0.1.0', {})
      expect(o.keys).to eq(%w{b@0.1})

      o = Lypack::Loader.find_matching_packages('b@~>0.2.0', {})
      expect(o.keys).to eq(%w{b@0.2 b@0.2.2})

      o = Lypack::Loader.find_matching_packages('c@~>0.1.0', {})
      expect(o.keys).to eq(%w{c@0.1})
      
      o = Lypack::Loader.find_matching_packages('c@>=0.2', {})
      expect(o.keys).to eq(%w{c@0.3})
    end
  end
  
  it "Returns a prepared hash of dependencies for a package reference" do
    with_package_setup(:simple) do
      o = {}
      Lypack::Loader.find_package_versions('b@>=0.2', o, o)
      
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
      o = Lypack::Loader.process('spec/user_files/simple.ly')
      expect(o[:dependencies].keys).to eq(%w{a c})

      expect(o[:dependencies]['a'][:versions].keys).to eq(%w{a@0.1 a@0.2})
      expect(o[:dependencies]['c'][:versions].keys).to eq(%w{c@0.1})

      expect(o[:dependencies]['a'][:versions]['a@0.1'][:dependencies].keys).to eq(%w{b})

      expect(o[:dependencies]['a'][:versions]['a@0.1'][:dependencies]['b'][:versions].keys).to eq(%w{b@0.1 b@0.2 b@0.2.2})
      
      r = Lypack::Resolver.resolve(o)
      expect(r).to eq(%w{a@0.1 b@0.1 c@0.1})
    end
  end
end

