require 'commander/import'
require "lyp/version"

program :name,            'lyp'
program :version,         Lyp::VERSION
program :description,     'Lyp is a package manager for lilypond.'
program :help_formatter,  :compact

require 'lyp/cli/commands'

default_command(:list)
