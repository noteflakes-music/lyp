require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lyp::Template" do
  it "renders a simple template" do
    tmpl = <<EOF
(1.._).each do |i|
  `{{i * 10}}: `
end
EOF
    t = Lyp::Template.new(tmpl)
    
    expect(t.render(5)).to eq("10: 20: 30: 40: 50: ")
  end
  
  it "renders a composite template" do
    a = <<EOF
(1.._).each do |i|
  __render__(:b, i + 3)
end
`
the end!`
EOF

    b = <<EOF
__render__(:c, _ * 2)
EOF

    c = <<EOF
`{{"*" * _}} `
EOF

    Lyp::Template.set(:a, a)
    Lyp::Template.set(:b, b)
    Lyp::Template.set(:c, c)
    
    expect(Lyp::Template.render(:a, 3)).to eq(
      "******** ********** ************ \nthe end!"
    )
  end
  
  it "correctly escapes and renders interpolated strings" do
    a = <<EOF
`{{"x" + 'y'}}`
EOF

    b = <<EOF
`{"x"}`
EOF

    Lyp::Template.set(:a, a)
    Lyp::Template.set(:b, b)

    expect(Lyp::Template.render(:a)).to eq("xy")
    expect(Lyp::Template.render(:b)).to eq("{\"x\"}")
  end
  
  it "correctly handles if blocks" do
    a = <<EOF
    `
    {{? false }} {{'abc'}} {{/}}
    {{? !!nil.nil? }}
    def
    {{/}}
    `
EOF

    Lyp::Template.set(:a, a)
    expect(Lyp::Template.render(:a).strip).to eq("def")
  end
end

