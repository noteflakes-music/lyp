require "lyp"
require "lyp/version"

INSTALL_MSG = <<EOF
Lyp is currently not installed. In order to use lyp, ~/.lyp/bin has to
be included in the shell $PATH.
EOF

# test installation
unless Lyp::ENV.installed?
  require 'highline'

  cli = HighLine.new
  STDERR.puts INSTALL_MSG.gsub("\n", " ")

  if cli.agree("Would you like to install lyp now? (yes/no)")
    Lyp::ENV.install!
    STDERR.puts "To finish installation please open a new shell"
    exit
  end
end

require 'commander/import'

program :name,            'lyp'
program :version,         Lyp::VERSION
program :description,     'Lyp is a package manager for lilypond.'
program :help_formatter,  :compact

require 'lyp/cli/commands'

default_command(:list)
