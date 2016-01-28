require 'fileutils'

module Lyp
  # A package specifier is of the form <package>@<version specifier>, where
  # the version specifier can be simply a version number, or include an operator
  # before the version number.
  # 
  # Accepted operators: >=, ~>
  PACKAGE_RE = /^([^@\>~]+)(?:@)?((?:\>=|~\>)?.+)?/
  LILYPOND_RE = /^lilypond(?:@?((?:\>=|~\>)?.+))?/

  LYP_DIRECTORY = File.expand_path('~/.lyp')
  LYP_BIN_DIRECTORY = File.join(LYP_DIRECTORY, 'bin')
  LYP_LIB_DIRECTORY = File.join(LYP_DIRECTORY, 'lib')
  DEFAULT_PACKAGE_DIRECTORY = File.join(LYP_DIRECTORY, 'packages')
  DEFAULT_LILYPONDS_DIRECTORY = File.join(LYP_DIRECTORY, 'lilyponds')
  
  # Fonts are installed on lilypond >= 2.18.2
  FONT_COPY_REQ = Gem::Requirement.new('>=2.18.2')
  FONT_PATCH_REQ = Gem::Requirement.new('>=2.18.2', '<2.19.12')
  
  # Font patch filename (required for 2.18.2 <= lilypond < 2.19.12)
  FONT_PATCH_FILENAME = File.expand_path('etc/font.scm', File.dirname(__FILE__))

  # etc/lyp.ly contains lyp:* procedure definitions for loading packages and
  # other support code.
  LYP_LY_LIB_PATH = File.expand_path('etc/lyp.ly', File.dirname(__FILE__))

  SETTINGS_FILENAME = 'settings.yml'
  
  def self.packages_dir
    ensure_dir(DEFAULT_PACKAGE_DIRECTORY)
  end
  
  def self.lilyponds_dir
    ensure_dir(DEFAULT_LILYPONDS_DIRECTORY)
  end

  def self.settings_file
    ensure_dir(LYP_DIRECTORY)
    File.join(LYP_DIRECTORY, SETTINGS_FILENAME)
  end
  
  def self.ensure_dir(dir)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    dir
  end
end

