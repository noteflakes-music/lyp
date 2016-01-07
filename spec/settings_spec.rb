require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lypack::Settings" do
  it "returns empty settings if settings file is missing" do
    with_packages(:simple) do
      expect(Lypack::Settings.get).to eq({})
    end
  end

  it "sets persistent settings" do
    with_packages(:simple) do
      expect(Lypack::Settings.get).to eq({})
      
      Lypack::Settings.set({a: {b: 'c'}})

      expect(Lypack::Settings.get).to eq({a: {b: 'c'}})
    end
  end
  
  it "sets and gets deep settings" do
    with_packages(:simple) do
      Lypack::Settings['a/b/c'] = 32
      
      expect(Lypack::Settings.get).to eq({a: {b: {c: 32}}})
      expect(Lypack::Settings['a/b/c']).to eq(32)
      expect(Lypack::Settings['a/b']).to eq({c: 32})

      Lypack::Settings['a/d'] = 'EFG'

      expect(Lypack::Settings.get).to eq({a: {b: {c: 32}, d: 'EFG'}})
      
    end
  end
end