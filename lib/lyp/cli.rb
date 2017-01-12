require 'thor'
require 'lyp/version'

def lilypond_prefix(info)
  if info[:current] && info[:default]
    "=* "
  elsif info[:current]
    "=> "
  elsif info[:default]
    " * "
  else
    "   "
  end
end

def lilypond_postfix(info)
  if info[:system]
    " (system)"
  else
    ""
  end
end

def format_lilypond_entry(info)
  "#{lilypond_prefix(info)}#{info[:version]}#{lilypond_postfix(info)}"
end

LILYPOND_PREAMBLE = <<EOF

Lilypond versions:

EOF

LILYPOND_LEGEND = <<EOF

# => - current
# =* - current && default
#  * - default

EOF

$cmd_options = {}

class Lyp::CLI < Thor
  package_name "lyp"
  map "-v" => :version,
      "c" => :compile,
      "i" => :install,
      "l" => :list,
      "s" => :search,
      "t" => :test,
      "u" => :uninstall,
      "U" => :use,
      "w" => :watch,
      "x" => :exec

  check_unknown_options! :except => [:compile, :watch, :benchmark]
  class_option :verbose, aliases: '-V', :type => :boolean, desc: 'show verbose output'

  no_commands do
    def search_lilypond(version)
      versions = Lyp::Lilypond.search(version)

      if versions.empty?
        puts "\nNo available versions of lilypond@#{version} found\n\n"
      else
        puts "\nAvailable versions of lilypond@#{version}:\n\n"
        versions.each do |v|
          prefix = v[:installed] ? " * " : "   "
          puts "#{prefix}#{v[:version]}"
        end
        puts "\n * Currently installed\n\n"
      end
    end

    PACKAGE_FMT = "%-16s => %s"

    def search_package(pattern)
      packages = Lyp::Package.list_lyp_index(pattern)
      if packages.empty?
        puts "\nNo matching package found in lyp-index\n\n"
      else
        puts "\nAvailable packages on lyp-index:\n\n"
        packages.each do |p|
          puts PACKAGE_FMT % [p['name'], p['description']]
          # puts "   #{p['name']}"
        end
        puts "\n\n"
      end
    end
  end

  desc "accelerate", "Rewrite gem binaries to make lyp faster"
  def accelerate
    unless Lyp::System.is_gem?
      puts "Lyp is not installed as a gem."
      exit 1
    end

    Lyp::System.rewrite_gem_scripts
  end

  desc "benchmark FILE", "Benchmark all installed versions of Lilypond"
  def benchmark(*argv)
    list = Lyp::Lilypond.list
    if list.empty?
      puts Lyp::LILYPOND_NOT_FOUND_MSG
    else
      list.each do |info|
        Lyp::Lilypond.force_version!(info[:version])
        t1 = Time.now
        compile("--invoke-quiet", *argv)
        t2 = Time.now
        puts "%-7s: %.3gs" % [info[:version], t2-t1]
      end
    end
  end

  desc "cleanup", "Cleanup temporary files"
  def cleanup
    $stderr.puts "Lyp #{Lyp::VERSION}"
    Dir["#{Lyp::TMP_ROOT}/*"].each do |fn|
      puts "Cleaning up #{fn}"
      FileUtils.rm_rf(fn)
    end
  end

  desc "compile [<option>...] <FILE>", "compile given file Lilypond source file"
  def compile(*argv)
    opts, argv = Lyp::Lilypond.preprocess_argv(argv)
    opts[:verbose] ||= options[:verbose]
    $cmd_options = opts

    lilypond_path = Lyp::Lilypond.select_lilypond_version(opts, argv.last)

    $stderr.puts "Lyp #{Lyp::VERSION}" unless opts[:mode] == :quiet
    Lyp::System.test_installed_status!
    Lyp::Lilypond.compile(argv, opts)
  end

  desc "deps FILE", "List dependencies found in user's files"
  def deps(fn)
    $cmd_options = options

    resolver = Lyp::DependencyResolver.new(fn)
    tree = resolver.compile_dependency_tree(ignore_missing: true)
    tree.dependencies.each do |package, spec|
      versions = spec.versions.keys.map {|k| k =~ Lyp::PACKAGE_RE; $2 }.sort
      if versions.empty?
        puts "   #{spec.clause} => (no local version found)"
      else
        puts "   #{spec.clause} => #{versions.join(', ')}"
      end
    end
  end

  desc "exec <CMD> [<options>...]", "Execute a lilypond script"
  def exec(*argv)
    $stderr.puts "Lyp #{Lyp::VERSION}"
    Lyp::System.test_installed_status!
    Lyp::Lilypond.invoke_script(argv, {})
  end

  desc "flatten FILE", "Flatten a file and included files into a single output file"
  method_option :include, aliases: '-I', type: :string, desc: 'Add to include search path'
  def flatten(input_path, output_path = nil)
    input_path = File.expand_path(input_path)
    output_path = File.expand_path(output_path) if output_path


    opts = {include_paths: []}
    if options[:include]
      opts[:include_paths] << options[:include]
    end
    if Lyp::Lilypond.current_lilypond
      opts[:include_paths] << Lyp::Lilypond.current_lilypond_include_path
    end

    flat = Lyp::Transform.flatten(input_path, opts)
    if output_path
      File.open(output_path, 'w+') {|f| f << flat}
    else
      puts flat
    end
  end

  desc "install <PACKAGE|lilypond|self>...", "Install a package or a version of Lilypond. When 'install self' is invoked, lyp installs itself in ~/.lyp."
  method_option :default, aliases: '-d', type: :boolean, desc: 'Set default Lilypond version'
  method_option :test, aliases: '-t', type: :boolean, desc: 'Run package tests after installation'
  method_option :dev, type: :boolean, desc: 'Install local development package'
  method_option :update, aliases: '-u', type: :boolean, desc: 'Remove any old versions of the package'
  def install(*args)
    $cmd_options = options

    if options[:dev]
      if args.empty?
        args = ["#{File.basename(FileUtils.pwd)}@dev:."]
      else
        args = args.map {|a| "#{File.basename(File.expand_path(a))}@dev:#{a}"}
      end
    end

    raise "No package specified" if args.empty?

    args.each do |package|
      case package
      when 'self'
        Lyp::System.install!
      when Lyp::LILYPOND_RE
        Lyp::System.test_installed_status!
        Lyp::Lilypond.install($1, options)
      else
        Lyp::System.test_installed_status!
        Lyp::Package.install(package, options)
      end
    end
  end

  desc "list [PATTERN|lilypond]", "List installed packages matching PATTERN or versions of Lilypond"
  def list(pattern = nil)
    $cmd_options = options

    Lyp::System.test_installed_status!

    if pattern == 'lilypond'
      list = Lyp::Lilypond.list
      if list.empty?
        puts Lyp::LILYPOND_NOT_FOUND_MSG
      else
        puts LILYPOND_PREAMBLE
        list.each {|info| puts format_lilypond_entry(info)}
        puts LILYPOND_LEGEND
      end
    else
      list = Lyp::Package.list(args.first)
      if list.empty?
        if args.first
          return puts "\nNo installed packages found matching '#{args.first}'\n\n"
        else
          return puts "\nNo packages are currently installed\n\n"
        end
      end

      by_package = list.inject({}) do |m, p|
        p =~ Lyp::PACKAGE_RE; (m[$1] ||= []) << $2; m
      end

      puts "\nInstalled packages:\n\n"
      by_package.keys.sort.each do |p|
        puts "   #{p} => (#{by_package[p].sort.join(', ')})"
      end
      puts "\n\n"
    end
  end

  desc "resolve FILE", "Resolve and install missing dependencies found in user's files"
  method_option :all, aliases: '-a', type: :boolean, desc: 'Install all found dependencies'
  def resolve(fn)
    $cmd_options = options

    resolver = Lyp::DependencyResolver.new(fn)
    tree = resolver.compile_dependency_tree(ignore_missing: true)
    tree.dependencies.each do |package, spec|
      if options[:all] || spec.versions.empty?
        Lyp::Package.install(spec.clause)
      end
    end
  end

  desc "search [PATTERN|lilypond]", "List available packages matching PATTERN or versions of lilypond"
  def search(pattern = '')
    $cmd_options = options

    pattern =~ Lyp::PACKAGE_RE
    package, version = $1, $2

    if package == 'lilypond'
      search_lilypond(version)
    else
      search_package(pattern)
    end
  end

  desc "test [<option>...] [.|PATTERN]", "Run package tests on installed packages or local directory"
  method_option :install, aliases: '-n', type: :boolean, desc: 'Install the requested version of Lilypond if not present'
  method_option :env, aliases: '-E', type: :boolean, desc: 'Use version set by LILYPOND_VERSION environment variable'
  method_option :use, aliases: '-u', type: :string, desc: 'Use specified version'
  def test(*args)
    $cmd_options = options
    test_opts = options.dup

    if test_opts[:env]
      unless ENV['LILYPOND_VERSION']
        STDERR.puts "$LILYPOND_VERSION not set"
        exit 1
      end
      test_opts[:use] = ENV['LILYPOND_VERSION']
    end

    if test_opts[:use]
      if test_opts[:install]
        Lyp::Lilypond.install_if_missing(test_opts[:use], no_version_test: true)
      end
      Lyp::Lilypond.force_version!(test_opts[:use])
    end

    # check lilypond default / current settings
    Lyp::Lilypond.check_lilypond!

    $stderr.puts "Lyp #{Lyp::VERSION}"
    case args
    when ['.']
      Lyp::Package.run_local_tests('.')
    else
      Lyp::Package.run_package_tests(args)
    end
  end

  desc "uninstall <PACKAGE|lilypond|self>...", "Uninstall a package or a version of Lilypond. When 'uninstall self' is invoked, lyp uninstalls itself from ~/.lyp."
  method_option :all, aliases: '-a', type: :boolean, desc: 'Uninstall all versions'
  def uninstall(*args)
    $cmd_options = options

    Lyp::System.test_installed_status!

    raise "No package specified" if args.empty?
    args.each do |package|
      case package
      when 'self'
        Lyp::System.uninstall!
      when Lyp::LILYPOND_RE
        Lyp::System.test_installed_status!
        Lyp::Lilypond.uninstall($1, options)
      else
        Lyp::System.test_installed_status!
        Lyp::Package.uninstall(package, options)
      end
    end
  end

  desc "update <PACKAGE>...", "Install a package after removing all previous versions"
  method_option :default, aliases: '-d', type: :boolean, desc: 'Set default Lilypond version'
  method_option :test, aliases: '-t', type: :boolean, desc: 'Run package tests after installation'
  def update(*args)
    invoke 'install', args, options.merge(update: true)
  end

  desc "use [lilypond@]<VERSION>", "Switch version of Lilypond"
  method_option :default, aliases: '-d', type: :boolean, desc: 'Set default Lilypond version'
  def use(version)
    $cmd_options = options

    Lyp::System.test_installed_status!

    if version =~ Lyp::LILYPOND_RE
      version = $1
    end

    lilypond = Lyp::Lilypond.use(version, options)
    puts "Using Lilypond version #{lilypond[:version]}"
  end

  desc "version", "show Lyp version"
  def version
    $stderr.puts "Lyp #{Lyp::VERSION}"
  end

  desc "watch PATH...", "Watch files and directories and recompile when a file changes"
  method_option :target, aliases: '-t', type: :string, desc: 'Set compile target'
  def watch(*paths)
    req_ext "directory_watcher"

    recompile_proc = lambda do |path|
      puts "#{path} changed"
      path = options[:target] || path
      puts "recompile #{path}"
      if path =~ /\.(i?)ly$/
        compile("--invoke-system", path)
      end
    end

    target = options[:target]

    watchers = paths.map do |path|
      if File.directory?(path)
        glob = ["**/*.ly", "**/*.ily", "**/*.scm"]
      else
        glob = [File.basename(path)]
        path = File.dirname(path)
      end

      puts "Watching #{path}"
      puts "glob: #{glob.inspect}"
      w = DirectoryWatcher.new(path, glob: glob, pre_load: true).tap do |w|
        w.interval = 0.1
        w.add_observer do |*events|
          events.each {|e| recompile_proc[e.path] if e.type == :modified}
        end
        w.start
      end
    end

    trap("INT") {watchers.each {|w| w.stop}; puts; exit}
    puts "Press ^C to exit"
    loop {sleep 1}
  end

  desc "which [PATTERN|lilypond]", "List locations of installed packages matching PATTERN or versions of Lilypond"
  def which(pattern = nil)
    $cmd_options = options

    Lyp::System.test_installed_status!

    if pattern == 'lilypond'
      current = Lyp::Lilypond.current_lilypond
      if current
        puts Lyp::Lilypond.current_lilypond
      else
        puts Lyp::LILYPOND_NOT_FOUND_MSG
      end
    else
      Lyp::Package.which(args.first).each {|p| puts p}
    end
  end

  def self.run
    trap("INT") {puts; exit}
    start(ARGV)
  rescue => e
    puts e.message
    puts e.backtrace.join("\n") if $cmd_options[:verbose]
    exit(1)
  end
end
