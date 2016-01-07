require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lypack::Lilypond" do
  it "returns a list of available lypack-installed lilyponds" do
    with_lilyponds(:empty) do
      list = Lypack::Lilypond.lypack_lilyponds
      expect(list).to be_empty
    end
    
    with_lilyponds(:simple) do
      list = Lypack::Lilypond.lypack_lilyponds.sort do |x, y|
        Gem::Version.new(x[:version]) <=> Gem::Version.new(y[:version])        
      end
      expect(list.map {|l| l[:version]}).to eq(%w{
        2.18.1 2.19.15 2.19.21
      })
    end
  end

  it "manages default lilypond setting" do
    with_lilyponds(:empty) do
      # get list and set default to latest version available
      Lypack::Lilypond.list
      expect(Lypack::Lilypond.default_lilypond).to be_nil
    end
    
    with_lilyponds(:simple) do
      # get list and set default to latest version available
      Lypack::Lilypond.list
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      
      Lypack::Lilypond.set_default_lilypond("#{$lilyponds_dir}/2.18.1/bin/lilypond")
      
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.1/bin/lilypond"
      )
      
    end
  end
  
  it "manages current lilypond setting" do
    with_lilyponds(:empty) do
      # get list and set default to latest version available
      Lypack::Lilypond.list
      expect(Lypack::Lilypond.current_lilypond).to be_nil
    end
    
    with_lilyponds(:simple) do
      # get list and set default to latest version available
      Lypack::Lilypond.list
      
      # current defaults to default
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      
      Lypack::Lilypond.set_current_lilypond("#{$lilyponds_dir}/2.18.1/bin/lilypond")
      
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.1/bin/lilypond"
      )
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
    end
  end

  it "installs an arbitrary version of lilypond" do
    with_lilyponds(:simple) do
      Lypack::Lilypond.list
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      
      Lypack::Lilypond.install("2.18.2", {silent: true})
      
      files = Dir["#{$lilyponds_dir}/2.18.2/bin/*"].map {|fn| File.basename(fn)}
      expect(files).to include('lilypond')
      
      resp = `#{$lilyponds_dir}/2.18.2/bin/lilypond -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq('2.18.2')
      
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.2/bin/lilypond"
      )
    end
  end
  
  it "installs and sets as default an arbitrary version of lilypond" do
    with_lilyponds(:simple) do
      Lypack::Lilypond.list
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      
      Lypack::Lilypond.install("2.18.2", {silent: true, default: true})
      
      files = Dir["#{$lilyponds_dir}/2.18.2/bin/*"].map {|fn| File.basename(fn)}
      expect(files).to include('lilypond')
      
      resp = `#{$lilyponds_dir}/2.18.2/bin/lilypond -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq('2.18.2')
      
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.2/bin/lilypond"
      )
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.2/bin/lilypond"
      )
    end
  end
  
  it "installs the latest stable version of lilypond" do
    with_lilyponds(:simple) do
      Lypack::Lilypond.list
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      
      version = Lypack::Lilypond.latest_stable_version
      
      Lypack::Lilypond.install('stable', {silent: true})
      
      files = Dir["#{$lilyponds_dir}/#{version}/bin/*"].map {|fn| File.basename(fn)}
      expect(files).to include('lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/bin/lilypond -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
      
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/#{version}/bin/lilypond"
      )
    end
  end
  
  it "installs the latest unstable version of lilypond" do
    with_lilyponds(:simple) do
      Lypack::Lilypond.list
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      
      version = Lypack::Lilypond.latest_unstable_version
      
      Lypack::Lilypond.install('unstable', {silent: true})
      
      files = Dir["#{$lilyponds_dir}/#{version}/bin/*"].map {|fn| File.basename(fn)}
      expect(files).to include('lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/bin/lilypond -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
      
      expect(Lypack::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/bin/lilypond"
      )
      expect(Lypack::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/#{version}/bin/lilypond"
      )
    end
  end
  
  it "supports version specifiers when installing lilypond" do
    with_lilyponds(:simple) do
      Lypack::Lilypond.install('>=2.18.1', {silent: true})
      version = Lypack::Lilypond.latest_version
      
      files = Dir["#{$lilyponds_dir}/#{version}/bin/*"].map {|fn| File.basename(fn)}
      expect(files).to include('lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/bin/lilypond -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
    end

    with_lilyponds(:simple) do
      Lypack::Lilypond.install('~>2.17.30', {silent: true})
      version = "2.17.97"
      
      files = Dir["#{$lilyponds_dir}/#{version}/bin/*"].map {|fn| File.basename(fn)}
      expect(files).to include('lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/bin/lilypond -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
    end
  end

  it "switches between installed versions of lilypond" do
    with_lilyponds(:simple) do
      Lypack::Lilypond.list
      expect(Lypack::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.21/bin/lilypond")
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/bin/lilypond")
      
      Lypack::Lilypond.use("2.18.1", {})
      expect(Lypack::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.21/bin/lilypond")
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.18.1/bin/lilypond")
      
      Lypack::Lilypond.use("2.19.15", {default: true})
      expect(Lypack::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.15/bin/lilypond")
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.15/bin/lilypond")

      Lypack::Lilypond.use("latest", {})
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/bin/lilypond")

      Lypack::Lilypond.use("stable", {})
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.18.1/bin/lilypond")

      Lypack::Lilypond.use("unstable", {})
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/bin/lilypond")

      Lypack::Lilypond.use("2.18", {})
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.18.1/bin/lilypond")

      Lypack::Lilypond.use(">=2.18", {})
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/bin/lilypond")

      Lypack::Lilypond.use("~>2.18.1", {})
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.18.1/bin/lilypond")
    end
    
    
  end

  it "uninstalls a local version of lilypond" do
    # create a copy of the lilypond setup
    FileUtils.cp_r("#{$spec_dir}/lilypond_setups/simple", "#{$spec_dir}/lilypond_setups/simple_copy")
    
    with_lilyponds(:simple_copy) do
      versions = Lypack::Lilypond.list.map {|l| l[:version]}
      expect(versions).to eq(%w{2.18.1 2.19.15 2.19.21})
      
      expect(Lypack::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.21/bin/lilypond")
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/bin/lilypond")

      # invalid versions
      expect {Lypack::Lilypond.uninstall("")}.to raise_error
      expect {Lypack::Lilypond.uninstall("stable")}.to raise_error
      expect {Lypack::Lilypond.uninstall(">=2.18")}.to raise_error
      expect {Lypack::Lilypond.uninstall("2.18.2")}.to raise_error
      
      Lypack::Lilypond.uninstall("2.19.21")
      versions = Lypack::Lilypond.list.map {|l| l[:version]}
      expect(versions).to eq(%w{2.18.1 2.19.15})

      expect(Lypack::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.15/bin/lilypond")
      expect(Lypack::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.15/bin/lilypond")

      Lypack::Lilypond.uninstall("2.18.1")
      Lypack::Lilypond.uninstall("2.19.15")
      versions = Lypack::Lilypond.list.map {|l| l[:version]}
      expect(versions).to eq([])

      expect(Lypack::Lilypond.default_lilypond).to be_nil
      expect(Lypack::Lilypond.current_lilypond).to be_nil
    end
  end
end

