require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp" do
  it "copies font files when installing a package with fonts" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Lilypond.install('2.18.1', silent: true)
        Lyp::Lilypond.install('2.18.2', silent: true)
        Lyp::Lilypond.install('2.19.11', silent: true)
        Lyp::Lilypond.install('2.19.12', silent: true)

        Lyp::Package.install("fonty@dev:#{$spec_dir}/user_files/fonty", silent: true)
        
        check_font_file = lambda do |version, path, positive = true|
          exists = File.file?("#{$lilyponds_dir}/#{version}/share/lilypond/current/fonts/#{path}")
          expect(exists).to eq(positive)
        end
        
        check_font_file['2.18.1', 'otf/berta.otf', false]
        check_font_file['2.18.1', 'svg/berta.svg', false]
        check_font_file['2.18.1', 'svg/berta.woff', false]
        
        %w{2.18.2 2.19.11 2.19.12}.each do |version|
          check_font_file[version, 'otf/berta.otf']
          check_font_file[version, 'svg/berta.svg']
          check_font_file[version, 'svg/berta.woff']
        end
        
        Lyp::Lilypond.install('2.19.35', silent: true)
        check_font_file['2.19.35', 'otf/berta.otf']
        check_font_file['2.19.35', 'svg/berta.svg']
        check_font_file['2.19.35', 'svg/berta.woff']
      end
    end
  end
  
  it "patches installed lilypond versions when < 2.19.12" do
    with_lilyponds(:empty) do
      with_packages(:tmp) do
        Lyp::Lilypond.install('2.18.1', silent: true)
        Lyp::Lilypond.install('2.18.2', silent: true)
        Lyp::Lilypond.install('2.19.11', silent: true)
        Lyp::Lilypond.install('2.19.12', silent: true)
        
        check_patch = lambda do |version, positive = true|
          fn = "#{$lilyponds_dir}/#{version}/share/lilypond/current/scm/font.scm"
          identical = IO.read(fn) == IO.read(Lyp::FONT_PATCH_FILENAME)
          
          expect(identical).to eq(positive)
        end
        
        check_patch['2.18.1', false]
        check_patch['2.18.2', true]
        check_patch['2.19.11', true]
        check_patch['2.19.12', false]
      end
    end
  end
end

