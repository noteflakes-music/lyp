require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "spec_helper" do
  it "correctly switches package setup dir" do
    with_packages(:simple) do
      expect(Lypack.packages_dir).to eq(
        File.expand_path('spec/package_setups/simple')
      )
    end
  end

  it "correctly switches lilypond setup dir" do
    with_lilyponds(:empty) do
      expect(Lypack.lilyponds_dir).to eq(
        File.expand_path('spec/lilypond_setups/empty')
      )
    end
  end
end

