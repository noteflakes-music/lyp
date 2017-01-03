require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp::Transform" do
  it "Flattens a file and any included files into a single output file" do
    out = Lyp::Transform.flatten("#{$spec_dir}/user_files/flattened_input.ly").gsub(
      "#{$spec_dir}/user_files/", ""
    ).strip_whitespace
    expect(out).to eq(IO.read("#{$spec_dir}/user_files/flattened_output.ly").strip_whitespace)
  end

  it "Flattens a file with stock lilypond includes and search paths" do
    with_lilyponds(:tmp, copy_from: :empty) do
      with_packages(:tmp, copy_from: :empty) do
        Lyp::Lilypond.install('2.19.37', silent: true)
        
        opts = {
          include_paths: [
            "#{$spec_dir}/include_files",
            Lyp::Lilypond.current_lilypond_include_path
          ]
        }
        out = Lyp::Transform.flatten("#{$spec_dir}/user_files/include_path.ly", opts).
        gsub("#{$spec_dir}/", "").
        strip_whitespace
        expect(out).to eq(IO.read("#{$spec_dir}/user_files/flattened_include_path.ly").strip_whitespace)
      end
    end
  end
end
