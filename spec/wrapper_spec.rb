require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe "Lypack.wrap" do
  it "returns the same filename for a file without dependencies" do
    fn = File.expand_path('user_files/no_require.ly', File.dirname(__FILE__))
    expect(Lypack.wrap(fn)).to eq(fn)
  end
  
  it "creates a wrapper file containing dependency paths for a file with dependencies" do
    with_package_setup(:simple) do
      orig_fn = File.expand_path('user_files/simple.ly', File.dirname(__FILE__))
      fn = Lypack.wrap(orig_fn)
      expect(fn).to_not eq(orig_fn)
      
      code = IO.read(fn)
      
      expect(code).to include("(hash-set! package-refs \"a\" \"#{$package_setup_dir}/a@0.1/package.ly\")")
      expect(code).to include("(hash-set! package-refs \"b@>=0.1.0\" \"#{$package_setup_dir}/b@0.1/package.ly\")")
      expect(code).to include("(hash-set! package-refs \"b@~>0.2.0\" \"#{$package_setup_dir}/b@0.1/package.ly\")")
      expect(code).to include("(hash-set! package-refs \"b@~>0.1.0\" \"#{$package_setup_dir}/b@0.1/package.ly\")")
      expect(code).to include("(hash-set! package-refs \"c\" \"#{$package_setup_dir}/c@0.1/package.ly\")")
    end
  end
end

