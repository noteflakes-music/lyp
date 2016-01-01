module Lypack
  LYPACK_DIRECTORY = File.expand_path('~/.lypack')
  LYPACK_BIN_DIRECTORY = File.join(LYPACK_DIRECTORY, 'bin')
  DEFAULT_PACKAGE_DIRECTORY = File.join(LYPACK_DIRECTORY, 'packages')

  def self.packages_dir
    DEFAULT_PACKAGE_DIRECTORY
  end
  
end

%w{
  output
  env
  
  template
  resolver
  wrapper
  
  package
}.each do |f|
  require File.expand_path("lypack/#{f}", File.dirname(__FILE__))
end
