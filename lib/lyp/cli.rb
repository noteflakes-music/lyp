require 'thor'
require "lyp/version"

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

class Lyp::CLI < Thor
  package_name "lyp"
  map "-v" => :version
  check_unknown_options! :except => :compile
  
  desc "version", "show Lyp version"
  def version
    require 'lyp/version'
    $stderr.puts "Lyp #{Lyp::VERSION}"
  end
  
  desc "list [PATTERN|lilypond]", "List installed packages matching PATTERN or versions of lilypond"
  def list(pattern = nil)
    Lyp::System.test_installed_status!

    if pattern == 'lilypond'
      STDOUT.puts LILYPOND_PREAMBLE
      Lyp::Lilypond.list.each {|info| puts format_lilypond_entry(info)}
      STDOUT.puts LILYPOND_LEGEND
    else
      Lyp::Package.list(args.first).each {|p| puts p}
    end
  end
  
  desc "search [PATTERN|lilypond]", "List available packages matching PATTERN or versions of lilypond"
  def search(pattern)
    # Lyp::System.test_installed_status!

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
        puts "\nNo versions of lilypond are available for download\n\n"
      else
        puts "\nAvailable versions of lilypond:\n\n"
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
        puts "\nAvailable packages:\n\n"
        packages.each do |p|
          puts "   #{p[:name]}"
        end
        puts "\n\n"
      end
    end
  end

  desc "compile [<option>...] <FILE>", "Invokes lilypond with given file"
  def compile(*args)
    Lyp::System.test_installed_status!
    Lyp::Lilypond.check_lilypond!

    Lyp::Lilypond.compile(*args)
  end

  desc "install <PACKAGE|lilypond|self>...", "Install a package or a version of lilypond. When 'install self' is invoked, lyp installs itself in ~/.lyp."
  method_option :default, aliases: '-d', type: :boolean, desc: 'Set default lilypond version'
  def install(*args)
    raise "No package specified" if args.empty?
    
    args.each do |package|
      case package
      when 'self'
        Lyp::System.install!
      when /^lilypond(?:@(.+))?$/
        Lyp::System.test_installed_status!
        Lyp::Lilypond.install($1, options)
      else
        Lyp::System.test_installed_status!
        Lyp::Package.install(package)
      end
    end
  end

  desc "uninstall <PACKAGE|lilypond|self>...", "Uninstall a package or a version of lilypond. When 'uninstall self' is invoked, lyp uninstalls itself from ~/.lyp."
  def uninstall(*args)
    Lyp::System.test_installed_status!

    raise "No package specified" if args.empty?
    args.each do |package|
      case package
      when 'self'
        Lyp::System.uninstall!
      when /^lilypond(?:@(.+))?$/
        Lyp::System.test_installed_status!
        Lyp::Lilypond.uninstall($1)
      else
        Lyp::System.test_installed_status!
        Lyp::Package.uninstall(package)
      end
    end
  end
  
  desc "use [lilypond@]<VERSION>", "Switch version of lilypond"
  method_option :default, aliases: '-d', type: :boolean, desc: 'Set default lilypond version'
  def use(version)
    Lyp::System.test_installed_status!

    if version =~ /^lilypond@(.+)$/
      version = $1
    end
  
    lilypond = Lyp::Lilypond.use(version, options)
    puts "Using version #{lilypond[:version]}"
  end
end

Lyp::CLI.start(ARGV)