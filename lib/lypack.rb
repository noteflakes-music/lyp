module Lypack
  LYPACK_DIRECTORY = File.expand_path('~/.lypack')
  LYPACK_BIN_DIRECTORY = File.join(LYPACK_DIRECTORY, 'bin')
  DEFAULT_PACKAGE_DIRECTORY = File.join(LYPACK_DIRECTORY, 'packages')
  
  SETTINGS_FILENAME = 'settings.yml'

  def self.packages_dir
    DEFAULT_PACKAGE_DIRECTORY
  end
  
  def self.settings_file
    File.join(LYPACK_DIRECTORY, SETTINGS_FILENAME)
  end
end

%w{
  output
  env
  
  settings
  
  template
  resolver
  wrapper
  
  package
  lilypond
}.each do |f|
  require File.expand_path("lypack/#{f}", File.dirname(__FILE__))
end
