module Lyp
  WRAPPER_TEMPLATE = Lyp::Template.new(IO.read(
    File.expand_path('templates/deps_wrapper.rb', File.dirname(__FILE__))
  ))

  WRAPPERS_DIR = "#{Lyp::TMP_ROOT}/wrappers"

  def self.wrap(fn, opts = {})
    r = Lyp::DependencyResolver.new(fn, opts).resolve_package_dependencies
    # copy current_package_dir option
    r[:current_package_dir] = opts[:current_package_dir]
    r[:opts] = opts

    FileUtils.mkdir_p(WRAPPERS_DIR)
    fn = "#{WRAPPERS_DIR}/#{File.basename(fn)}"

    File.open(fn, 'w+') {|f| f << WRAPPER_TEMPLATE.render(r)}

    fn
  end
end
