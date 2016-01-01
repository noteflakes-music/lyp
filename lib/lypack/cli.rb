require "lypack"
require "lypack/version"

INSTALL_MSG = <<EOF
Lypack is currently not installed. In order to use lypack, ~/.lypack/bin has to
be included in the shell $PATH.
EOF

# test installation
unless Lypack::ENV.installed?
  require 'highline'

  cli = HighLine.new
  STDERR.puts INSTALL_MSG.gsub("\n", " ")

  if cli.agree("Would you like to install lypack now? (yes/no)")
    Lypack::ENV.install!
    STDERR.puts "To finish installation please open a new shell"
    exit
  end
end

require 'commander/import'

program :name,            'lypack'
program :version,         Lypack::VERSION
program :description,     'Lypack is a package manager for lilypond.'
program :help_formatter,  :compact


command :list do |c|
  c.syntax =      "list [PATTERN]"
  c.description = "Lists installed versions of packages whose name matches PATTERN"
  c.action do |args, opts|
    Lypack::Package.list(args.first).each {|p| puts p}
  end
end

default_command(:list)
