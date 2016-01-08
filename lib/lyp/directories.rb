require 'fileutils'

module Lyp
  # A package specifier is of the form <package>@<version specifier>, where
  # the version specifier can be simply a version number, or include an operator
  # before the version number. Accepted operators: >=, ~>
  PACKAGE_RE = /^([^@]+)(?:@(.+))?$/

  LYPACK_DIRECTORY = File.expand_path('~/.lyp')
  LYPACK_BIN_DIRECTORY = File.join(LYPACK_DIRECTORY, 'bin')
  DEFAULT_PACKAGE_DIRECTORY = File.join(LYPACK_DIRECTORY, 'packages')
  DEFAULT_LILYPONDS_DIRECTORY = File.join(LYPACK_DIRECTORY, 'lilyponds')
  
  SETTINGS_FILENAME = 'settings.yml'

  def self.packages_dir
    ensure_dir(DEFAULT_PACKAGE_DIRECTORY)
  end
  
  def self.lilyponds_dir
    ensure_dir(DEFAULT_LILYPONDS_DIRECTORY)
  end

  def self.settings_file
    ensure_dir(LYPACK_DIRECTORY)
    File.join(LYPACK_DIRECTORY, SETTINGS_FILENAME)
  end
  
  def self.ensure_dir(dir)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    dir
  end
end

