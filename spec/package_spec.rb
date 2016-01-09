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
    
    # using lyp-index
    expect(Lyp::Package.package_git_url('dummy')).to eq(
    "https://github.com/noteflakes/lyp-package-template.git"
    )
    
    expect {Lyp::Package.package_git_url('blah')}.to raise_error
  end
  
  it "correctly converts a git URL to a local temp path" do
    expect(Lyp::Package.git_url_to_temp_path("https://github.com/ciconia/stylush.git")).to eq(
      "/tmp/lyp/repos/github.com/ciconia/stylush"
    )

    expect(Lyp::Package.git_url_to_temp_path("http://down.load/myrepo.git")).to eq(
      "/tmp/lyp/repos/down.load/myrepo"
    )
    
    expect(Lyp::Package.git_url_to_temp_path("git@github.com:e/f.git")).to eq(
      "/tmp/lyp/repos/github.com/e/f"
    )
  end

  it "correctly converts a git URL to a package path" do
    with_packages(:simple) do
      expect(Lyp::Package.git_url_to_package_path("dummy", '0.2.1')).to eq(
        "#{Lyp::packages_dir}/dummy@0.2.1"
      )

      expect(Lyp::Package.git_url_to_package_path("https://github.com/ciconia/stylush.git", nil)).to eq(
        "#{Lyp::packages_dir}/github.com/ciconia/stylush@head"
      )

      expect(Lyp::Package.git_url_to_package_path("http://down.load/myrepo.git", "sometag")).to eq(
        "#{Lyp::packages_dir}/down.load/myrepo@sometag"
      )
    
      expect(Lyp::Package.git_url_to_package_path("git@github.com:e/f.git", "2.13.2")).to eq(
        "#{Lyp::packages_dir}/github.com/e/f@2.13.2"
      )
    end
  end

  it "correctly lists tags for a package repo" do
    tmp_dir = "/tmp/lyp-dummy-repo"
    FileUtils.rm_rf(tmp_dir)
    repo = Rugged::Repository.clone_at('https://github.com/noteflakes/lyp-package-template', tmp_dir)
    tags = Lyp::Package.repo_tags(repo)
    versions = tags.map {|t| Lyp::Package.tag_version(t)}
    expect(versions).to eq(%w{0.1.0 0.2.0 0.2.1 0.3.0})
  end
  
  it "correctly selects the highest versioned tag for a given version specifier" do
    tmp_dir = "/tmp/lyp-dummy-repo"
    FileUtils.rm_rf(tmp_dir)
    repo = Rugged::Repository.clone_at('https://github.com/noteflakes/lyp-package-template', tmp_dir)

    select = lambda do |v|
      tag = Lyp::Package.select_git_tag(repo, v)
      tag && tag.name
    end
    
    expect(select[nil]).to be_nil
    expect(select["0.2.0"]).to eq("v0.2.0")
    expect(select[">=0.1.0"]).to eq("v0.3.0")
    expect(select["~>0.1.0"]).to eq("v0.1.0")
    expect(select["~>0.2.0"]).to eq("v0.2.1")
  end
  
  it "installs multiple versions of a package" do
    FileUtils.rm_rf("#{$spec_dir}/package_setups/simple_copy")
    # create a copy of the packages setup
    FileUtils.cp_r("#{$spec_dir}/package_setups/simple", "#{$spec_dir}/package_setups/simple_copy")

    with_packages(:simple_copy) do
      version = Lyp::Package.install('dummy')
      expect(version).to eq("head")
      
      paths = Dir["#{$packages_dir}/dummy*"].map {|fn| File.basename(fn)}
      expect(paths).to eq(['dummy@head'])
      
      expect(Lyp::Package.list('dummy')).to eq(['dummy@head'])

      version = Lyp::Package.install('dummy@0.2.0')
      expect(version).to eq("0.2.0")

      version = Lyp::Package.install('dummy@~>0.1.0')
      expect(version).to eq("0.1.0")

      version = Lyp::Package.install('dummy@~>0.2.0')
      expect(version).to eq("0.2.1")

      version = Lyp::Package.install('dummy@>=0.1.0')
      expect(version).to eq("0.3.0")

      expect(Lyp::Package.list('dummy')).to eq(%w{
        dummy@0.1.0 dummy@0.2.0 dummy@0.2.1 dummy@0.3.0 dummy@head
      })

    end
    
  end
end