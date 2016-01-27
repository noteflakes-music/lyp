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

      expect(Lyp::Package.list('a@>=0.1')).to eq(%w{
        a@0.1
        a@0.2
      })

      expect(Lyp::Package.list('a>=0.2')).to eq(%w{
        a@0.2
      })

      expect(Lyp::Package.list('c')).to eq(%w{
        c@0.1
        c@0.3
      })
    end
  end

  it "returns a list of package locations for a given pattern" do
    with_packages(:simple) do
      expect(Lyp::Package.which('b@~>0.2')).to eq([
        "#{$packages_dir}/b@0.2",
        "#{$packages_dir}/b@0.2.2"
      ])

      expect(Lyp::Package.which('b~>0.2')).to eq([
        "#{$packages_dir}/b@0.2",
        "#{$packages_dir}/b@0.2.2"
      ])

      expect(Lyp::Package.which('c')).to eq([
        "#{$packages_dir}/c@0.1",
        "#{$packages_dir}/c@0.3"
      ])

      expect(Lyp::Package.which('a@0.1.0')).to eq([
        "#{$packages_dir}/a@0.1"
      ])
    end
  end

  it "lists nested packages" do
    with_packages(:simple_with_nested_packages) do
      expect(Lyp::Package.list).to eq(%w{
        a@0.1
        a@0.2
        acme.com/mypack@1.4.0
        b@0.1
        b@0.2
        b@0.2.2
        c@0.1
        c@0.3
        github.com/test/dummy@dev
      })
    end
  end

  it "lists packages matching given pattern" do
    with_packages(:simple_with_nested_packages) do
      expect(Lyp::Package.list('a')).to eq(%w{
        a@0.1
        a@0.2
        acme.com/mypack@1.4.0
      })
    end

    with_packages(:simple_with_nested_packages) do
      expect(Lyp::Package.list('c')).to eq(%w{
        acme.com/mypack@1.4.0
        c@0.1
        c@0.3
        github.com/test/dummy@dev
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
        "#{Lyp::packages_dir}/github.com/ciconia/stylush"
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
    repo = Rugged::Repository.clone_at('https://github.com/noteflakes/lyp-package-template.git', tmp_dir)
    tags = Lyp::Package.repo_tags(repo)
    versions = tags.map {|t| Lyp::Package.tag_version(t.name)}
    expect(versions).to eq(%w{0.1.0 0.2.0 0.2.1 0.3.0})
  end
  
  it "correctly selects the correct checkout ref for a given version specifier" do
    tmp_dir = "/tmp/lyp-dummy-repo"
    FileUtils.rm_rf(tmp_dir)
    repo = Rugged::Repository.clone_at('https://github.com/noteflakes/lyp-package-template', tmp_dir)

    select = lambda {|v| Lyp::Package.select_checkout_ref(repo, v)}
    
    expect(select[nil]).to eq("v0.3.0")
    expect(select["latest"]).to eq("v0.3.0")
    expect(select["master"]).to eq("master")
    expect(select["0.2.0"]).to eq("v0.2.0")
    expect(select[">=0.1.0"]).to eq("v0.3.0")
    expect(select["~>0.1.0"]).to eq("v0.1.0")
    expect(select["~>0.2.0"]).to eq("v0.2.1")
  end
  
  it "installs multiple versions of a package" do
    with_packages(:tmp) do
      # When no version is specified, lyp should install the highest tagged 
      # version
      version = Lyp::Package.install('dummy', silent: true)
      expect(version).to eq("0.3.0")

      paths = Dir["#{$packages_dir}/dummy*"].map {|fn| File.basename(fn)}
      expect(paths).to eq(['dummy@0.3.0'])

      expect(Lyp::Package.list('dummy')).to eq(['dummy@0.3.0'])

      version = Lyp::Package.install('dummy@0.2.0', silent: true)
      expect(version).to eq("0.2.0")

      version = Lyp::Package.install('dummy@~>0.1.0', silent: true)
      expect(version).to eq("0.1.0")

      version = Lyp::Package.install('dummy~>0.2.0', silent: true)
      expect(version).to eq("0.2.1")

      version = Lyp::Package.install('dummy@>=0.1.0', silent: true)
      expect(version).to eq("0.3.0")

      version = Lyp::Package.install('dummy>=0.1.0', silent: true)
      expect(version).to eq("0.3.0")

      expect(Lyp::Package.list('dummy')).to eq(%w{
        dummy@0.1.0 dummy@0.2.0 dummy@0.2.1 dummy@0.3.0
      })
    end
  end
  
  it "installs package from git url" do
    with_packages(:tmp) do
      # When no version is specified, lyp should install the highest tagged 
      # version
      version = Lyp::Package.install('github.com/noteflakes/lyp-package-template', silent: true)
      expect(version).to eq("0.3.0")

      paths = Dir["#{$packages_dir}/**/package.ly"].map do |fn|
        File.dirname(fn).gsub("#{$packages_dir}/", "")
      end
      expect(paths).to eq(['github.com/noteflakes/lyp-package-template@0.3.0'])

      expect(Lyp::Package.list('templ')).to eq(
        ['github.com/noteflakes/lyp-package-template@0.3.0']
      )
    end
  end
  
  it "installs transitive dependencies for the installed package" do
    with_packages(:tmp) do
      version = Lyp::Package.install('dependency-test@0.1', silent: true)
      expect(version).to eq("0.1.0")
      
      dirs = Dir["#{$packages_dir}/*"].map {|fn| File.basename(fn)}
      expect(dirs.sort).to eq(%w{dependency-test@0.1.0 dummy@0.3.0})

      version = Lyp::Package.install('dependency-test>=0.2.0', silent: true)
      expect(version).to eq("0.2.0")
      
      dirs = Dir["#{$packages_dir}/*"].map {|fn| File.basename(fn)}
      expect(dirs.sort).to eq(%w{
        dependency-test@0.1.0
        dependency-test@0.2.0
        dummy@0.2.1
        dummy@0.3.0
      })
    end
  end
  
  it "installs a package from local files" do
    with_packages(:tmp) do
      version = Lyp::Package.install("abc@dev:#{$spec_dir}/user_files/dev_dir1", silent: true)
      expect(version).to eq("dev")
      
      dirs = Dir["#{$packages_dir}/*"].map {|fn| File.basename(fn)}
      expect(dirs.sort).to eq(["abc@dev"])
      
      # check that lyp creates a package.ly file in the package dir,
      # referencing the given directory
      dir = Dir["#{$packages_dir}/abc@dev/*"]
      expect(dir.map {|fn| File.basename(fn)}).to eq(['package.ly'])

      package_dir_statement = "#(set! lyp:current-package-dir \"#{$spec_dir}/user_files/dev_dir1\")\n"
      include_statement = "\\include \"#{$spec_dir}/user_files/dev_dir1/package.ly\"\n"
      fn = IO.read(dir[0])
      expect(fn).to include(package_dir_statement)
      expect(fn).to include(include_statement)

      
      # reference a specific file (relative path)
      version = Lyp::Package.install("abc@dev2:spec/user_files/dev_dir2/dev_file.ly", silent: true)
      expect(version).to eq("dev2")
      
      dirs = Dir["#{$packages_dir}/*"].map {|fn| File.basename(fn)}
      expect(dirs.sort).to eq(%w{abc@dev abc@dev2})
      
      dir = Dir["#{$packages_dir}/abc@dev2/*"]
      expect(dir.map {|fn| File.basename(fn)}).to eq(['package.ly'])

      package_dir_statement = "#(set! lyp:current-package-dir \"#{$spec_dir}/user_files/dev_dir2\")\n"
      include_statement = "\\include \"#{$spec_dir}/user_files/dev_dir2/dev_file.ly\""
      fn = IO.read(dir[0])
      expect(fn).to include(package_dir_statement)
      expect(fn).to include(include_statement)

      # should raise if package.ly is not there
      expect {
        Lyp::Package.install("abc@dev3:#{$spec_dir}/user_files/dev_dir2", silent: true)
      }.to raise_error
      expect(dirs.sort).to eq(%w{abc@dev abc@dev2})

      # should raise if invalid path
      expect {
        Lyp::Package.install("abc@dev4:spec/user_files/invalid", silent: true)
      }.to raise_error
      expect(dirs.sort).to eq(%w{abc@dev abc@dev2})

    end
  end
  
  it "uninstalls a package" do
    with_packages(:tmp) do
      Lyp::Package.install('dependency-test@0.1', silent: true)
      
      dirs = Dir["#{$packages_dir}/*"].map {|fn| File.basename(fn)}
      expect(dirs.sort).to eq(%w{dependency-test@0.1.0 dummy@0.3.0})
      
      Lyp::Package.uninstall('dependency-test@0.1.0', silent: true)
      dirs = Dir["#{$packages_dir}/*"].map {|fn| File.basename(fn)}
      expect(dirs.sort).to eq(%w{dummy@0.3.0})
      
      Lyp::Package.install('dependency-test@0.1.0', silent: true)
      Lyp::Package.install('dependency-test@0.2.0', silent: true)
      Lyp::Package.uninstall('dependency-test', silent: true, all: true)

      dirs = Dir["#{$packages_dir}/*"].map {|fn| File.basename(fn)}
      expect(dirs.sort).to eq(%w{dummy@0.2.1 dummy@0.3.0})

      expect {Lyp::Package.uninstall('dependency-test@0.1.0', silent: true)}.to \
        raise_error
    end
    
    with_packages(:tmp, copy_from: :unversioned) do
      Lyp::Package.uninstall('b', silent: true)
      expect(Dir["#{$packages_dir}/*"]).to eq([])
    end
  end

  it "uninstalls a package from git url" do
    with_packages(:tmp) do
      expect {Lyp::Package.uninstall('github.com/noteflakes/lyp-package-template@0.3.0', silent: true)}.to \
        raise_error

      Lyp::Package.install('github.com/noteflakes/lyp-package-template', silent: true)
      expect(Lyp::Package.list('templ')).to eq(
        ['github.com/noteflakes/lyp-package-template@0.3.0']
      )
      
      Lyp::Package.uninstall('github.com/noteflakes/lyp-package-template@0.3.0', silent: true)
      expect(Lyp::Package.list('templ')).to be_empty
      
      Lyp::Package.install('github.com/noteflakes/lyp-package-template', silent: true)
      expect(Lyp::Package.list('templ')).to eq(
        ['github.com/noteflakes/lyp-package-template@0.3.0']
      )
      
      Lyp::Package.uninstall('github.com/noteflakes/lyp-package-template', silent: true, all: true)
      expect(Lyp::Package.list('templ')).to be_empty
    end
  end
end