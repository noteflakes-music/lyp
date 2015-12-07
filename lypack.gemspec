require File.expand_path("./lib/lypack/version", File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name          = 'lypack'
  s.version       = Lypack::VERSION

  s.summary       = "Lypack is package manager for lilypond"
  s.description   = "Lypack is a tool for managing lilypond versions and lilypond packages"
  s.authors       = ["Sharon Rosner"]
  s.email         = 'ciconia@gmail.com'

  s.homepage      = 'http://github.com/ciconia/lypack'
  s.license       = 'MIT'

  s.require_path  = 'lib'
  s.files         = Dir["{lib}/**/*", "bin/*", "LICENSE", "README.md"]

  s.executables   = ['lypack']

  s.add_dependency "thor", "0.19.1"
  s.add_dependency "ruby-progressbar", "1.7.5"
end
