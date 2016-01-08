require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp::Package" do
  it "returns a list of installed packages" do
    with_packages(:simple) do
      expect(Lyp::Package.list).to eq(%w{
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
      expect(Lyp::Package.list).to eq(%w{
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
      expect(Lyp::Package.list('a')).to eq(%w{
        a@0.1
        a@0.2
      })
    end

    with_packages(:simple_with_ly) do
      expect(Lyp::Package.list('0.1')).to eq(%w{
        a@0.1
        b@0.1
        c@0.1
      })
    end
  end

  it "correctly converts a package name to a git url" do
    expect(Lyp::Package.package_git_url('ciconia/stylush')).to eq(
      "https://github.com/ciconia/stylush.git"
    )
    
    expect(Lyp::Package.package_git_url('github.com/a/b')).to eq(
      "https://github.com/a/b.git"
    )
    
    expect(Lyp::Package.package_git_url('acme.de/c/d')).to eq(
      "https://acme.de/c/d.git"
    )
    
    expect(Lyp::Package.package_git_url('http://down.load/myrepo.git')).to eq(
      "http://down.load/myrepo.git"
    )

    expect(Lyp::Package.package_git_url('git@github.com:e/f.git')).to eq(
      "git@github.com:e/f.git"
    )
    
    expect {Lyp::Package.package_git_url('blah')}.to raise_error
  end
  
  it "correctly converts a git URL to a local temp path" do
    expect(Lyp::Package.git_url_to_local_path("https://github.com/ciconia/stylush.git")).to eq(
      "/tmp/lyp/repos/github.com/ciconia/stylush"
    )

    expect(Lyp::Package.git_url_to_local_path("http://down.load/myrepo.git")).to eq(
      "/tmp/lyp/repos/down.load/myrepo"
    )
    
    expect(Lyp::Package.git_url_to_local_path("git@github.com:e/f.git")).to eq(
      "/tmp/lyp/repos/github.com/e/f"
    )
  end

end