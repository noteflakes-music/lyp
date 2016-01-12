%w{
  base
  system
  settings
  
  template
  resolver
  wrapper
  
  package
  lilypond
}.each do |f|
  require File.expand_path("lyp/#{f}", File.dirname(__FILE__))
end
