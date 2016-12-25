module Kernel
  @@ext_requires = {}
  def req_ext(l)
    @@ext_requires[l] ||= require(l)
  end

  LYP_RB_DIR = File.expand_path("lyp", File.dirname(__FILE__))
  def req_int(f)
    require File.join(LYP_RB_DIR, f)
  end
end

Kernel.req_int 'base'
Kernel.req_int 'system'
Kernel.req_int 'settings'

Kernel.req_int 'template'
Kernel.req_int 'resolver'
Kernel.req_int 'wrapper'
Kernel.req_int 'package'
Kernel.req_int 'lilypond'
Kernel.req_int 'transform'

Kernel.req_int 'windows' if Lyp::WINDOWS
