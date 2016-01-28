require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp scheme interface" do
  it "passes scheme assertions" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Lilypond.install('2.18.2', silent: true)
        Lyp::Package.install("assert>=0.1.3", silent: true)
        
        test_file = "#{$spec_dir}/user_files/scheme_interface_test.ly"
        ok = Lyp::Lilypond.compile([test_file], force_wrap: true)
        expect(ok).to eq(true)
      end
    end
  end  
end

RSpec.describe "assert package" do
  it "passes tests" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Lilypond.install('2.18.2', silent: true)
        Lyp::Package.install("assert", silent: true)
        
        stats = Lyp::Package.run_package_tests(['assert'], 
          silent: true, dont_exit: true)
          
        expect(stats[:test_count]).to eq(1)
        expect(stats[:fail_count]).to eq(0)
      end
    end    
  end
end

