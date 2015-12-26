require 'tempfile'

module Lypack
  def self.wrap(fn)
    r = Lypack::Resolver.new(fn).resolve_package_dependencies

    unless r[:package_paths].empty?
      fn = Tempfile.new('lypack-deps-wrapper.ly').path
  
      t = Lypack::Template.new(IO.read(File.expand_path('templates/deps_wrapper.rb', File.dirname(__FILE__))))
      File.open(fn, 'w+') {|f| f << t.render(r)}
    end
    fn
  end
end