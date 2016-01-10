require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp" do
  it "installs lilypond+package and compiles successfully" do
    with_lilyponds(:empty) do
      FileUtils.rm_rf("#{$spec_dir}/package_setups/simple_copy")
      FileUtils.mkdir("#{$spec_dir}/package_setups/simple_copy")

      with_packages(:simple_copy) do
        Lyp::Lilypond.install('2.19.35', {silent: true})
        Lyp::Package.install('dummy', silent: true)
        
        Lyp::Lilypond.compile(["#{$spec_dir}/user_files/the-works.ly"])
        
        expect($_out).to match(/Hello from package/)
      end
    end
  end
end

