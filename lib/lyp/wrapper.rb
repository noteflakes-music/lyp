require 'tempfile'

module Lyp
  def self.wrap(fn)
    r = Lyp::Resolver.new(fn).resolve_package_dependencies

    unless r[:package_paths].empty?
      fn = Tempfile.new('lyp-deps-wrapper.ly').path
  
      t = Lyp::Template.new(IO.read(File.expand_path('templates/deps_wrapper.rb', File.dirname(__FILE__))))
      File.open(fn, 'w+') {|f| f << t.render(r)}
    end
    fn
  end
end