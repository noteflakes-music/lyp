require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp scheme interface" do
  it "passes scheme assertions" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Package.install("assert@0.2.0", silent: true)
        test_file = "#{$spec_dir}/user_files/scheme_interface_test.ly"

        Lyp::Lilypond.install('2.18.2', silent: true)
        expect(Lyp::Lilypond.compile([test_file])).to eq(true)

        Lyp::Lilypond.install('2.19.36', silent: true)
        expect(Lyp::Lilypond.compile([test_file])).to eq(true)
      end
    end
  end  
end

RSpec.describe "assert package" do
  it "passes tests when installed" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Lilypond.install('2.18.2', silent: true)
        Lyp::Package.install("assert@0.2.0", silent: true)
        
        stats = Lyp::Package.run_package_tests(['assert'], 
          silent: true, dont_exit: true)
          
        expect(stats[:test_count]).to eq(1)
        expect(stats[:fail_count]).to eq(0)
      end
    end    
  end
  
  it "passes tests when cloned locally" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Lilypond.install('2.18.2', silent: true)
        
        url = "https://github.com/noteflakes/lyp-assert.git"
        repo_path = "#{Lyp::TMP_ROOT}/assert-clone"
        FileUtils.rm_rf(repo_path)
        Rugged::Repository.clone_at(url, repo_path)

        FileUtils.cd(repo_path) do
          stats = Lyp::Package.run_local_tests('.', 
            silent: true, dont_exit: true)
          
          expect(stats[:test_count]).to eq(1)
          expect(stats[:fail_count]).to eq(0)
        end
      end
    end
  end
end

