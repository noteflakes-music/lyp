require 'tempfile'

module Lyp
  WRAPPER_TEMPLATE = Lyp::Template.new(IO.read(
    File.expand_path('templates/deps_wrapper.rb', File.dirname(__FILE__))
  ))
  
  def self.wrap(fn, opts = {})
    r = Lyp::Resolver.new(fn, opts).resolve_package_dependencies

    # copy current_package_dir option
    r[:current_package_dir] = opts[:current_package_dir]
    r[:opts] = opts

    FileUtils.mkdir_p("#{Lyp::TMP_ROOT}/wrappers")
    fn = "#{Lyp::TMP_ROOT}/wrappers/#{File.basename(fn)}" 
  
    File.open(fn, 'w+') {|f| f << WRAPPER_TEMPLATE.render(r)}
    
    fn
  end
end