require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp::Settings" do
  it "returns empty settings if settings file is missing" do
    with_packages(:simple) do
      expect(Lyp::Settings.load).to eq({})
    end
  end

  it "sets persistent settings" do
    with_packages(:simple) do
      expect(Lyp::Settings.load).to eq({})

      Lyp::Settings['a/b'] = 'c'
      Lyp::Settings.save

      expect(Lyp::Settings.load).to eq({a: {b: 'c'}})
    end
  end

  it "sets and gets deep settings" do
    with_packages(:simple) do
      Lyp::Settings['a/b/c'] = 32

      expect(Lyp::Settings.load).to eq({a: {b: {c: 32}}})
      expect(Lyp::Settings['a/b/c']).to eq(32)
      expect(Lyp::Settings['a/b']).to eq({c: 32})

      Lyp::Settings['a/d'] = 'EFG'

      expect(Lyp::Settings.load).to eq({a: {b: {c: 32}, d: 'EFG'}})
    end
  end

  it "sets and gets arbitrary value types" do
    with_packages(:simple) do
      expect(Lyp::Settings.get_value('a/b')).to eq(nil)
      expect(Lyp::Settings.get_value('a/b', 123)).to eq(123)

      Lyp::Settings.set_value('a/b', 456)
      expect(Lyp::Settings.get_value('a/b', 123)).to eq(456)

      Lyp::Settings.set_value('a/c', 'abc')
      expect(Lyp::Settings.get_value('a/c', 123)).to eq('abc')

      t = Time.now
      Lyp::Settings.set_value('a/c', t)
      expect(Lyp::Settings.get_value('a/c', 123)).to eq(t)
    end
  end
end
