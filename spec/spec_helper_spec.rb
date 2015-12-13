require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "spec_helper" do
  it "correctly switches package setup dir" do
    with_package_setup(:simple) do
      expect(Lypack::Loader.packages_dir).to eq(
        File.expand_path('spec/setups/simple')
      )
    end
  end
end

