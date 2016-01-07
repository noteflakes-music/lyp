require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lypack::Package" do
  it "returns a list of installed packages" do
    with_packages(:simple) do
      expect(Lypack::Package.list).to eq(%w{
        a@0.1
        a@0.2
        b@0.1
        b@0.2
        b@0.2.2
        c@0.1
        c@0.3
      })
    end
  end

  it "list lilypond versions" do
    with_packages(:simple_with_ly) do
      expect(Lypack::Package.list).to eq(%w{
        a@0.1
        a@0.2
        b@0.1
        b@0.2
        b@0.2.2
        c@0.1
        c@0.3
        lilypond@2.6.2
        lilypond@2.19.34
      })
    end
  end

  it "lists packages matching given pattern" do
    with_packages(:simple_with_ly) do
      expect(Lypack::Package.list('a')).to eq(%w{
        a@0.1
        a@0.2
      })
    end

    with_packages(:simple_with_ly) do
      expect(Lypack::Package.list('0.1')).to eq(%w{
        a@0.1
        b@0.1
        c@0.1
      })
    end
  end
end