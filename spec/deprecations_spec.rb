require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "\\pinclude" do
  def resolver(tree = Lyp::DependencyLeaf.new, opts = {})
    Lyp::DependencyResolver.new(tree, opts)
  end

  it "should call load the referenced file" do
    with_packages(:simple) do
      r = resolver('spec/user_files/include1.ly').resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.1 c@0.1})
    end
  end

  it "should issue a deprecation warning" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Lilypond.install('2.19.36', silent: true)
        test_file = "#{$spec_dir}/user_files/pinclude3.ly"
        output = Lyp::Lilypond.compile([test_file], verbose: true, mode: :capture)

        expect(output).to match(/hello from pinclude4/)
        expect(output).to match(/warning\: .+ deprecated/)
      end
    end
  end
end
