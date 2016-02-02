def req(f); require File.expand_path("lyp/#{f}", File.dirname(__FILE__)); end

req 'base'
req 'system'
req 'settings'

Lyp::System.test_rugged_gem!

req 'template'
req 'resolver'
req 'wrapper'
req 'package'
req 'lilypond'
