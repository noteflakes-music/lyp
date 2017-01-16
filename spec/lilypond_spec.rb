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

  it "correctly passes include paths to resolver" do
    with_lilyponds(:tmp, copy_from: :empty) do
      with_packages(:tmp, copy_from: :empty) do
        Lyp::Lilypond.install('2.19.37', silent: true)
        
        # fn = "#{$spec_dir}/user_files/include_stock.ly"
        # expect {Lyp::Lilypond.compile([fn])}.to_not raise_error

        fn = "#{$spec_dir}/user_files/include_path.ly"
        include_path = "#{$spec_dir}/include_files"

        opts, argv = Lyp::Lilypond.preprocess_argv(["--include", include_path, fn])

        expect {Lyp::Lilypond.compile(argv, opts)}.to_not raise_error
      end
    end
  end
end

RSpec.describe "Lilypond.preprocess_argv" do
  it "supports -A/--auto-install-deps" do
    argv = ["-A", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({resolve: true})
    expect(a).to eq(["myfile.ly"])

    argv = ["--auto-install-deps", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({resolve: true})
    expect(a).to eq(["myfile.ly"])
  end

  it "supports -c/--cropped" do
    argv = ["-c", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({})
    expect(a).to eq(['-dbackend=eps', '-daux-files=#f', 'myfile.ly'])

    argv = ["--cropped", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({})
    expect(a).to eq(['-dbackend=eps', '-daux-files=#f', 'myfile.ly'])
  end

  it "supports -E/--env" do
    argv = ["-E", "myfile.ly"]
    expect(proc {Lyp::Lilypond.preprocess_argv(argv)}).to raise_error

    argv = ["--env", "myfile.ly"]
    expect(proc {Lyp::Lilypond.preprocess_argv(argv)}).to raise_error

    ENV["LILYPOND_VERSION"] = "2.19.53"

    argv = ["-E", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({use_version: "2.19.53"})
    expect(a).to eq(['myfile.ly'])

    argv = ["--env", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({use_version: "2.19.53"})
    expect(a).to eq(['myfile.ly'])
  end

  it "supports -F/--force-version" do
    argv = ["-F", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({force_version: true})
    expect(a).to eq(["myfile.ly"])

    argv = ["--force-version", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({force_version: true})
    expect(a).to eq(["myfile.ly"])
  end

  it "tracks include directories" do
    argv = ["-I", "foo/bar", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({include_paths: ["foo/bar"]})
    expect(a).to eq(["--include=foo/bar", "myfile.ly"])

    argv = ["-Ifoo/bar", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({include_paths: ["foo/bar"]})
    expect(a).to eq(["--include=foo/bar", "myfile.ly"])

    argv = ["-AFIfoo/bar", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({resolve: true, force_version: true, include_paths: ["foo/bar"]})
    expect(a).to eq(["--include=foo/bar", "myfile.ly"])

    argv = ["--include", "foo/bar", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({include_paths: ["foo/bar"]})
    expect(a).to eq(["--include=foo/bar", "myfile.ly"])
  end    

  it "supports -M/--music" do
    argv = ["-M", "c4 d e f"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(IO.read(a[0])).to eq("{ c4 d e f }")

    argv = ["--music", "c4 d e f"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(IO.read(a[0])).to eq("{ c4 d e f }")
  end

  it "supports -m/--music-relative" do
    argv = ["-m", "c4 d e f"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(IO.read(a[0])).to eq("\\relative c' { c4 d e f }")

    argv = ["--music-relative", "c4 d e f"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(IO.read(a[0])).to eq("\\relative c' { c4 d e f }")
  end

  it "supports -n/--install" do
    argv = ["-n", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({install: true})
    expect(a).to eq(["myfile.ly"])

    argv = ["--install", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({install: true})
    expect(a).to eq(["myfile.ly"])
  end

  it "supports -r/--require" do
    argv = ["-r", "assert", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({ext_require: ["assert"]})
    expect(a).to eq(["myfile.ly"])

    argv = ["-rassert", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({ext_require: ["assert"]})
    expect(a).to eq(["myfile.ly"])

    argv = ["--require", "assert", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({ext_require: ["assert"]})
    expect(a).to eq(["myfile.ly"])

    argv = ["--require=assert", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({ext_require: ["assert"]})
    expect(a).to eq(["myfile.ly"])

    argv = ["-rassert", "-rslash", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({ext_require: ["assert", "slash"]})
    expect(a).to eq(["myfile.ly"])
  end    

  it "supports -R/--raw" do
    argv = ["-R", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({raw: true})
    expect(a).to eq(["myfile.ly"])

    argv = ["--raw", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({raw: true})
    expect(a).to eq(["myfile.ly"])
  end

  it "supports -S/--snippet" do
    argv = ["-S", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({snippet_paper_preamble: true})
    expect(a).to eq(['-dbackend=eps', '-daux-files=#f', '--png', '-dresolution=600', "myfile.ly"])

    argv = ["--snippet", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({snippet_paper_preamble: true})
    expect(a).to eq(['-dbackend=eps', '-daux-files=#f', '--png', '-dresolution=600', "myfile.ly"])
  end

  it "supports -u/--use" do
    argv = ["-u", "2.19.35", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({use_version: "2.19.35"})
    expect(a).to eq(["myfile.ly"])

    argv = ["-u2.19.36", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({use_version: "2.19.36"})
    expect(a).to eq(["myfile.ly"])

    argv = ["--use", "2.19.37", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({use_version: "2.19.37"})
    expect(a).to eq(["myfile.ly"])

    argv = ["--use=2.19.38", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({use_version: "2.19.38"})
    expect(a).to eq(["myfile.ly"])
  end    
  
  it "supports -V/--verbose" do
    argv = ["-V", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({verbose: true})
    expect(a).to eq(["-V", "myfile.ly"])

    argv = ["--verbose", "myfile.ly"]
    o, a = Lyp::Lilypond.preprocess_argv(argv)
    expect(o).to eq({verbose: true})
    expect(a).to eq(["--verbose", "myfile.ly"])
  end
end
