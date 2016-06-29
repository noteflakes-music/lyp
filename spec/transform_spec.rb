require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp::Transform" do
  it "Flattens a file and any included files into a single output file" do
    out = Lyp::Transform.flatten("#{$spec_dir}/user_files/flattened_input.ly").gsub(
      "#{$spec_dir}/user_files/", ""
    ).strip_whitespace
    expect(out).to eq(IO.read("#{$spec_dir}/user_files/flattened_output.ly").strip_whitespace)
  end
end
