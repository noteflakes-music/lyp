# package commands

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

command :list do |c|
  c.syntax =      "list [PATTERN]"
  c.description = "Lists installed versions of packages whose name matches PATTERN"
  c.action do |args, opts|
    pattern = args.first
    if pattern.nil? || pattern == 'lilypond'
      STDOUT.puts LILYPOND_PREAMBLE
      Lypack::Lilypond.list.each {|info| puts format_lilypond_entry(info)}
      STDOUT.puts LILYPOND_LEGEND
    else
      Lypack::Package.list(args.first).each {|p| puts p}
    end
  end
end

command :compile do |c|
  c.syntax = "compile <FILE>"
  c.description = "Resolves package dependencies and invokes lilypond"
  c.action do |args, opts|
    begin
      raise "File not specified" if args.empty?
      Lypack::Lilypond.compile(ARGV[1..-1])
    rescue => e
      STDERR.puts e.message
      exit 1
    end
  end
end

command :search do |c|
  c.syntax = "search <PATTERN>"
  c.description = "Search for a package or a version of lilypond"
  c.action do |args, opts|
    pattern = args.first
    if pattern == 'lilypond'
      begin
        versions = Lypack::Lilypond.search
        versions.each {|v| puts v}
      rescue => e
        STDERR.puts e.message
        exit 1
      end
    end
  end
end

command :install do |c|
  c.syntax = "install <PACKAGE...>"
  c.description = "Install a package or a version of lilypond"
  c.option "-d", "--default", "Set default version"
  c.action do |args, opts|
    begin
      raise "No package specified" if args.empty?
      
      args.each do |package|
        if package =~ /^lilypond(?:@(.+))?$/
          Lypack::Lilypond.install($1, opts.__hash__)
        end
      end
    rescue => e
      STDERR.puts e.message
      exit 1
    end
  end
end

command :use do |c|
  c.syntax = "use [lilypond@]<VERSION>"
  c.description = "Switch version of lilypond"
  c.option "-d", "--default", "Set default version"

  c.action do |args, opts|
    begin
      version = args.first
      if version =~ /^lilypond@(.+)$/
        version = $1
      end
      
      lilypond = Lypack::Lilypond.use(version, opts.__hash__)
      puts "Using version #{lilypond[:version]}"
    rescue => e
      STDERR.puts e.message
      exit 1
    end
  end
end