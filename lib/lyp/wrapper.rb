require 'tempfile'

module Lyp
  WRAPPER_TEMPLATE = Lyp::Template.new(IO.read(
    File.expand_path('templates/deps_wrapper.rb', File.dirname(__FILE__))
  ))
  
  def self.wrap(fn)
    r = Lyp::Resolver.new(fn).resolve_package_dependencies

    unless r[:package_paths].empty?
      FileUtils.mkdir_p('/tmp/lyp/wrappers')
      fn = "/tmp/lyp/wrappers/#{File.basename(fn)}" 
           #Tempfile.new('lyp-deps-wrapper.ly').path
  
      File.open(fn, 'w+') {|f| f << WRAPPER_TEMPLATE.render(r)}
    end
    fn
  end
end