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
  map "-v" => :version
  check_unknown_options! :except => :compile
  class_option :verbose, aliases: '-V', :type => :boolean
  
  desc "version", "show Lyp version"
  def version
    $stderr.puts "Lyp #{Lyp::VERSION}"
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
  
    def search_package(pattern)
      packages = Lyp::Package.list_lyp_index(pattern)
      if packages.empty?
        puts "\nNo matching package found in lyp-index\n\n"
      else
        puts "\nAvailable packages on lyp-index:\n\n"
        packages.each do |p|
          puts "   #{p[:name]}"
        end
        puts "\n\n"
      end
    end
  end

  desc "compile [<option>...] <FILE>", "Invokes lilypond with given file"
  method_option :install, aliases: '-i', type: :boolean, desc: 'Install the requested version of lilypond if not present'
  method_option :env, aliases: '-e', type: :boolean, desc: 'Use version set by LILYPOND_VERSION environment variable'
  def compile(*args)
    $cmd_options = options

    $stderr.puts "Lyp #{Lyp::VERSION}"
    Lyp::System.test_installed_status!

    if options[:env]
      Lyp::Lilypond.force_env_version!
      if options[:install] && !Lyp::Lilypond.forced_lilypond
        Lyp::Lilypond.install(Lyp::Lilypond.forced_version)
      end
    else
      # check lilypond default / current settings
      Lyp::Lilypond.check_lilypond!
    end
    
    Lyp::Lilypond.compile(args)
  end
  
  desc "test [<option>...] [.|PATTERN]", "Runs package tests on installed packages or local directory"
  method_option :install, aliases: '-n', type: :boolean, desc: 'Install the requested version of lilypond if not present'
  method_option :env, aliases: '-E', type: :boolean, desc: 'Use version set by LILYPOND_VERSION environment variable'
  method_option :use, aliases: '-u', type: :string, desc: 'Use specified version'
  def test(*args)
    $cmd_options = options

    $stderr.puts "Lyp #{Lyp::VERSION}"

    if options[:env]
      unless ENV['LILYPOND_VERSION']
        STDERR.puts "$LILYPOND_VERSION not set"
        exit 1
      end
      options[:use] = ENV['LILYPOND_VERSION']
    end
    
    if options[:use]
      if options[:install]
        Lyp::Lilypond.install_if_missing(options[:use], no_version_test: true)
      end
      Lyp::Lilypond.force_version!(options[:use])
    end

    # check lilypond default / current settings
    Lyp::Lilypond.check_lilypond!
    
    case args
    when ['.']
      Lyp::Package.run_local_tests('.')
    else
      Lyp::Package.run_package_tests(args)
    end
  end

  desc "install <PACKAGE|lilypond|self>...", "Install a package or a version of lilypond. When 'install self' is invoked, lyp installs itself in ~/.lyp."
  method_option :default, aliases: '-d', type: :boolean, desc: 'Set default lilypond version'
  method_option :test, aliases: '-t', type: :boolean, desc: 'Run package tests after installation'
  def install(*args)
    $cmd_options = options

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

  desc "uninstall <PACKAGE|lilypond|self>...", "Uninstall a package or a version of lilypond. When 'uninstall self' is invoked, lyp uninstalls itself from ~/.lyp."
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
  
  desc "use [lilypond@]<VERSION>", "Switch version of lilypond"
  method_option :default, aliases: '-d', type: :boolean, desc: 'Set default lilypond version'
  def use(version)
    $cmd_options = options

    Lyp::System.test_installed_status!

    if version =~ Lyp::LILYPOND_RE
      version = $1
    end
  
    lilypond = Lyp::Lilypond.use(version, options)
    puts "Using version #{lilypond[:version]}"
  end

  desc "list [PATTERN|lilypond]", "List installed packages matching PATTERN or versions of lilypond"
  def list(pattern = nil)
    $cmd_options = options

    Lyp::System.test_installed_status!

    if pattern == 'lilypond'
      STDOUT.puts LILYPOND_PREAMBLE
      Lyp::Lilypond.list.each {|info| puts format_lilypond_entry(info)}
      STDOUT.puts LILYPOND_LEGEND
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
  
  desc "which [PATTERN|lilypond]", "List locations of installed packages matching PATTERN or versions of lilypond"
  def which(pattern = nil)
    $cmd_options = options

    Lyp::System.test_installed_status!

    if pattern == 'lilypond'
      puts Lyp::Lilypond.current_lilypond
    else
      Lyp::Package.which(args.first).each {|p| puts p}
    end
  end
  
  desc "deps FILE", "Lists dependencies found in user's files"
  def deps(fn)
    $cmd_options = options

    resolver = Lyp::Resolver.new(fn)
    tree = resolver.get_dependency_tree(ignore_missing: true)
    tree[:dependencies].each do |package, leaf|
      versions = leaf[:versions].keys.map {|k| k =~ Lyp::PACKAGE_RE; $2 }.sort
      if versions.empty?
        puts "   #{leaf[:clause]} => (no local version found)"
      else
        puts "   #{leaf[:clause]} => #{versions.join(', ')}"
      end
    end
  end
  
  desc "resolve FILE", "Resolves and installs missing dependencies found in user's files"
  method_option :all, aliases: '-a', type: :boolean, desc: 'Install all found dependencies'
  def resolve(fn)
    $cmd_options = options

    resolver = Lyp::Resolver.new(fn)
    tree = resolver.get_dependency_tree(ignore_missing: true)
    tree[:dependencies].each do |package, leaf|
      if options[:all] || leaf[:versions].empty?
        Lyp::Package.install(leaf[:clause])
      end
    end
  end
end

begin
  Lyp::CLI.start(ARGV)
rescue => e
  puts e.message
  puts e.backtrace.join("\n") if $cmd_options[:verbose]
  exit(1)
end