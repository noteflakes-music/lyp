require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp" do
  it "installs lilypond+package and compiles successfully" do
    with_lilyponds(:empty) do
      FileUtils.rm_rf("#{$spec_dir}/package_setups/tmp")
      FileUtils.mkdir("#{$spec_dir}/package_setups/tmp")

      with_packages(:tmp) do
        Lyp::Lilypond.install('2.19.35', {silent: true})
        Lyp::Package.install('dummy', silent: true)
        
        Lyp::Lilypond.compile(["#{$spec_dir}/user_files/the-works.ly"])
        
        expect($_out).to match(/Hello from package/)
      end
    end
  end
  
  it "correctly sets global lyp variables" do
    with_lilyponds(:empty) do
      with_packages(:test_vars) do
        Lyp::Lilypond.install('2.19.35', {silent: true})
        
        user_file = "#{$spec_dir}/user_files/test_vars.ly"
        
        Lyp::Lilypond.compile([user_file])
        
        expect($_out).to include("input-filename: #{user_file}")
        expect($_out).to include("input-dirname: #{File.dirname(user_file)}")
        expect($_out).to include("current-package-dir: #{$packages_dir}/b@0.2")
        expect($_out).to include("bvar: hello from b/inc/include1.ly")
        
      end
    end
  end
end

