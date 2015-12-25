require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lypack::Template" do
  it "renders a simple template" do
    tmpl = <<EOF
(1.._).each do |i|
  `\#{i * 10}: `
end
EOF
    t = Lypack::Template.new(tmpl)
    
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
`\#{"*" * _} `
EOF

    Lypack::Template.set(:a, a)
    Lypack::Template.set(:b, b)
    Lypack::Template.set(:c, c)
    
    expect(Lypack::Template.render(:a, 3)).to eq(
      "******** ********** ************ \nthe end!"
    )
  end
end

