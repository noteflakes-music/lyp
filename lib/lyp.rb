def req_int(f)
  require File.expand_path("lyp/#{f}", File.dirname(__FILE__))
end

module Kernel
  @@ext_requires = {}
  def req_ext(l)
    @@ext_requires[l] ||= require(l)
  end
end 

req_int 'base'
req_int 'system'
req_int 'settings'

req_int 'template'
req_int 'resolver'
req_int 'wrapper'
req_int 'package'
req_int 'lilypond'
req_int 'transform'

req_int 'windows' if Lyp::WINDOWS
