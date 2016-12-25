require File.expand_path("./lib/lyp/version", File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name          = 'lyp-win'
  s.version       = Lyp::VERSION

  s.summary       = "Lyp is a package manager for lilypond"
  s.description   = "Lyp is a tool for managing lilypond versions and lilypond packages"
  s.authors       = ["Sharon Rosner"]
  s.email         = 'ciconia@gmail.com'

  s.homepage      = 'http://github.com/noteflakes/lyp'
  s.license       = 'MIT'

  s.require_path  = 'lib'
  s.files         = Dir["{lib}/**/*", "bin/*", "LICENSE", "README.md"]

  s.executables   = ['lyp', 'lilypond']

  s.add_dependency "httpclient", "~>2.7", ">=2.7.1"
  s.add_dependency "ruby-progressbar", "~>1.7", ">=1.7.5"
  s.add_dependency "thor", "~>0.19", ">=0.19.1"
  s.add_dependency "directory_watcher", "1.5.1"
end
