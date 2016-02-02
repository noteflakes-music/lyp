require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp" do
  it "installs lilypond+package and compiles successfully" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Lilypond.install('2.19.35', silent: true)
        Lyp::Package.install('dummy', silent: true)
        
        Lyp::Lilypond.compile(["#{$spec_dir}/user_files/the-works.ly"])
        
        output = "#{$_out}\n#{$_err}"
        expect(output).to match(/Hello from package/)
      end
    end
  end
  
  it "correctly sets global lyp variables" do
    with_lilyponds(:empty) do
      with_packages(:test_vars) do
        Lyp::Lilypond.install('2.19.35', silent: true)
        
        user_file = "#{$spec_dir}/user_files/test_vars.ly"
        
        Lyp::Lilypond.compile([user_file])
        
        output = "#{$_out}\n#{$_err}"
        expect(output).to include("input-filename: #{user_file}")
        expect(output).to include("input-dirname: #{File.dirname(user_file)}")
        expect(output).to include("current-package-dir: #{$packages_dir}/b@0.2")
        expect(output).to include("bvar: hello from b/inc/include1.ly")
        
      end
    end
  end
end

