require File.expand_path('spec_helper', File.dirname(__FILE__))

$LILYPOND_BIN_DIR = Lyp::WINDOWS ? "usr/bin" : "bin"
$LILYPOND_BIN = Lyp::WINDOWS ? 
  "#{$LILYPOND_BIN_DIR}/lilypond.exe" : "#{$LILYPOND_BIN_DIR}/lilypond"

RSpec.describe "Lyp::Lilypond" do
  it "returns a list of available lyp-installed lilyponds" do
    with_lilyponds(:empty) do
      list = Lyp::Lilypond.lyp_lilyponds
      expect(list).to be_empty
    end
    
    with_lilyponds(:simple) do
      list = Lyp::Lilypond.lyp_lilyponds.sort do |x, y|
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
      Lyp::Lilypond.list
      expect(Lyp::Lilypond.default_lilypond).to be_nil
    end
    
    with_lilyponds(:simple) do
      # get list and set default to latest version available
      Lyp::Lilypond.list
      expect(Lyp::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}"
      )
      
      Lyp::Lilypond.set_default_lilypond("#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN}")
      
      expect(Lyp::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN}"
      )
      
    end
  end
  
  it "manages current lilypond setting" do
    with_lilyponds(:empty) do
      # get list and set default to latest version available
      Lyp::Lilypond.list
      expect(Lyp::Lilypond.current_lilypond).to be_nil
      expect(Lyp::Lilypond.current_lilypond_bin_path).to be_nil
    end
    
    with_lilyponds(:simple) do
      # get list and set default to latest version available
      Lyp::Lilypond.list
      
      # current defaults to default
      expect(Lyp::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond_bin_path).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN_DIR}"
      )
      
      Lyp::Lilypond.set_current_lilypond("#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN}")
      
      expect(Lyp::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond_bin_path).to eq(
        "#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN_DIR}"
      )
      expect(Lyp::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}"
      )
    end
  end

  it "installs an arbitrary version of lilypond" do
    with_lilyponds(:simple) do
      Lyp::Lilypond.list
      expect(Lyp::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond_bin_path).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN_DIR}"
      )
      
      Lyp::Lilypond.install("2.18.2", silent: true)
      
      files = Dir["#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN_DIR}/*"].map {|fn| File.basename(fn)}
      expect(files).to include(Lyp::WINDOWS ? 'lilypond.exe' : 'lilypond')
      
      resp = `#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN} -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq('2.18.2')
      
      expect(Lyp::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond_bin_path).to eq(
        "#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN_DIR}"
      )
    end
  end
  
  it "installs and sets as default an arbitrary version of lilypond" do
    with_lilyponds(:simple) do
      Lyp::Lilypond.list
      expect(Lyp::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond_bin_path).to eq(
        "#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN_DIR}"
      )
      
      Lyp::Lilypond.install("2.18.2", {silent: true, default: true})
      
      files = Dir["#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN_DIR}/*"].map {|fn| File.basename(fn)}
      expect(files).to include(Lyp::WINDOWS ? 'lilypond.exe' : 'lilypond')
      
      resp = `#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN} -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq('2.18.2')
      
      expect(Lyp::Lilypond.default_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond).to eq(
        "#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN}"
      )
      expect(Lyp::Lilypond.current_lilypond_bin_path).to eq(
        "#{$lilyponds_dir}/2.18.2/#{$LILYPOND_BIN_DIR}"
      )
    end
  end
  
  it "installs the latest stable version of lilypond" do
    with_lilyponds(:simple) do
      version = Lyp::Lilypond.latest_stable_version
      Lyp::Lilypond.install('stable', silent: true)
      
      files = Dir["#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN_DIR}/*"].map {|fn| File.basename(fn)}
      expect(files).to include(Lyp::WINDOWS ? 'lilypond.exe' : 'lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN} -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
    end
  end
  
  it "installs the latest unstable version of lilypond" do
    with_lilyponds(:simple) do
      version = Lyp::Lilypond.latest_unstable_version
      Lyp::Lilypond.install('unstable', silent: true)
      
      files = Dir["#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN_DIR}/*"].map {|fn| File.basename(fn)}
      expect(files).to include(Lyp::WINDOWS ? 'lilypond.exe' : 'lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN} -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
    end
  end
  
  it "installs the latest version of lilypond" do
    with_lilyponds(:simple) do
      version = Lyp::Lilypond.latest_version
      Lyp::Lilypond.install('latest', silent: true)
      
      files = Dir["#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN_DIR}/*"].map {|fn| File.basename(fn)}
      expect(files).to include(Lyp::WINDOWS ? 'lilypond.exe' : 'lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN} -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
    end
  end
  
  it "supports version specifiers when installing lilypond" do
    with_lilyponds(:simple) do
      Lyp::Lilypond.install('>=2.18.1', silent: true)
      version = Lyp::Lilypond.latest_version
      
      files = Dir["#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN_DIR}/*"].map {|fn| File.basename(fn)}
      expect(files).to include(Lyp::WINDOWS ? 'lilypond.exe' : 'lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN} -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
    end

    with_lilyponds(:simple) do
      Lyp::Lilypond.install('~>2.17.30', silent: true)
      version = "2.17.97"
      
      files = Dir["#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN_DIR}/*"].map {|fn| File.basename(fn)}
      expect(files).to include(Lyp::WINDOWS ? 'lilypond.exe' : 'lilypond')
      
      resp = `#{$lilyponds_dir}/#{version}/#{$LILYPOND_BIN} -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq(version)
    end
  end

  it "switches between installed versions of lilypond" do
    with_lilyponds(:simple) do
      Lyp::Lilypond.list
      expect(Lyp::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}")
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}")
      
      Lyp::Lilypond.use("2.18.1", {})
      expect(Lyp::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}")
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN}")
      
      Lyp::Lilypond.use("2.19.15", {default: true})
      expect(Lyp::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.15/#{$LILYPOND_BIN}")
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.15/#{$LILYPOND_BIN}")

      Lyp::Lilypond.use("latest", {})
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}")

      Lyp::Lilypond.use("stable", {})
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN}")

      Lyp::Lilypond.use("unstable", {})
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}")

      Lyp::Lilypond.use("2.18", {})
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN}")

      Lyp::Lilypond.use(">=2.18", {})
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}")

      Lyp::Lilypond.use("~>2.18.1", {})
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.18.1/#{$LILYPOND_BIN}")
    end
    
    
  end

  it "uninstalls a local version of lilypond" do
    with_lilyponds(:tmp, copy_from: :simple) do
      versions = Lyp::Lilypond.list.map {|l| l[:version]}
      expect(versions).to eq(%w{2.18.1 2.19.15 2.19.21})
      
      expect(Lyp::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}")
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.21/#{$LILYPOND_BIN}")

      # invalid versions
      expect {Lyp::Lilypond.uninstall(nil, silent: true)}.to raise_error
      expect {Lyp::Lilypond.uninstall("~>2.17.0", silent: true)}.to raise_error
      expect {Lyp::Lilypond.uninstall("abc", silent: true)}.to raise_error
      
      Lyp::Lilypond.uninstall("2.19.21", silent: true)
      versions = Lyp::Lilypond.list.map {|l| l[:version]}
      expect(versions).to eq(%w{2.18.1 2.19.15})

      expect(Lyp::Lilypond.default_lilypond).to eq("#{$lilyponds_dir}/2.19.15/#{$LILYPOND_BIN}")
      expect(Lyp::Lilypond.current_lilypond).to eq("#{$lilyponds_dir}/2.19.15/#{$LILYPOND_BIN}")

      Lyp::Lilypond.uninstall("2.18.1", silent: true)
      Lyp::Lilypond.uninstall("2.19.15", silent: true)
      versions = Lyp::Lilypond.list.map {|l| l[:version]}
      expect(versions).to eq([])

      expect(Lyp::Lilypond.default_lilypond).to be_nil
      expect(Lyp::Lilypond.current_lilypond).to be_nil
    end
  end
  
  it "provides a list of versions available for download" do
    with_lilyponds(:tmp, copy_from: :simple) do
      versions = Lyp::Lilypond.list.map {|l| l[:version]}
      expect(versions).to eq(%w{2.18.1 2.19.15 2.19.21})
      
      versions = Lyp::Lilypond.search
      
      v = versions.find {|l| l[:version] == "2.19.15"}
      expect(v[:installed]).to eq(true)
      
      v = versions.find {|l| l[:version] == "2.19.30"}
      expect(v[:installed]).to eq(false)
      
      versions = Lyp::Lilypond.search('~>2.18.0')
      expect(versions.map{|l| l[:version]}).to eq(%w{2.18.0 2.18.1 2.18.2})
    end
  end
  
  it "accepts command-line require option for compilation" do
    with_lilyponds(:tmp, copy_from: :empty) do
      with_packages(:tmp, copy_from: :empty) do
        Lyp::Lilypond.install('2.19.37', silent: true)
        Lyp::Package.install('assert', silent: true)
        
        Lyp::Lilypond.compile(["#{$spec_dir}/user_files/no_require.ly"],
          {ext_require: ['assert']})
        
        output = "#{$_out}\n#{$_err}"
        expect(output).to match(/Fine/)
      end
    end
  end
end

