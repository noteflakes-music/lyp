require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp::Settings" do
  it "returns empty settings if settings file is missing" do
    with_packages(:simple) do
      expect(Lyp::Settings.get).to eq({})
    end
  end

  it "sets persistent settings" do
    with_packages(:simple) do
      expect(Lyp::Settings.get).to eq({})
      
      Lyp::Settings.set({a: {b: 'c'}})

      expect(Lyp::Settings.get).to eq({a: {b: 'c'}})
    end
  end
  
  it "sets and gets deep settings" do
    with_packages(:simple) do
      Lyp::Settings['a/b/c'] = 32
      
      expect(Lyp::Settings.get).to eq({a: {b: {c: 32}}})
      expect(Lyp::Settings['a/b/c']).to eq(32)
      expect(Lyp::Settings['a/b']).to eq({c: 32})

      Lyp::Settings['a/d'] = 'EFG'

      expect(Lyp::Settings.get).to eq({a: {b: {c: 32}, d: 'EFG'}})
      
    end
  end
end