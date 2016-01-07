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
    with_lilyponds(:empty) do
      Lypack::Lilypond.install("2.18.1", {silent: true})
      
      files = Dir["#{$lilyponds_dir}/2.18.1/bin/*"].map {|fn| File.basename(fn)}
      expect(files).to include('lilypond')
      
      resp = `#{$lilyponds_dir}/2.18.1/bin/lilypond -v`
      resp =~ /LilyPond ([0-9\.]+)/i
      expect($1).to eq('2.18.1')
    end
  end
end

