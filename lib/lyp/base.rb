require 'fileutils'

module Lyp
  WINDOWS = Gem.win_platform?
  TMP_DIR = WINDOWS ? "#{Dir.home}/AppData/Local/Temp" : "/tmp"
  TMP_ROOT = "#{TMP_DIR}/lyp"
  FileUtils.mkdir_p(TMP_ROOT)

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
  LYP_EXT_DIRECTORY = File.join(LYP_DIRECTORY, 'ext')
  DEFAULT_PACKAGE_DIRECTORY = File.join(LYP_DIRECTORY, 'packages')
  DEFAULT_LILYPONDS_DIRECTORY = File.join(LYP_DIRECTORY, 'lilyponds')
  
  # Fonts are installed on lilypond >= 2.18.2
  FONT_COPY_REQ = Gem::Requirement.new('>=2.18.2')
  FONT_PATCH_REQ = Gem::Requirement.new('>=2.18.2', '<2.19.12')
  
  ETC_DIRECTORY = File.join(File.dirname(__FILE__), 'etc')
  
  # Font patch filename (required for 2.18.2 <= lilypond < 2.19.12)
  FONT_PATCH_FILENAME = File.join(ETC_DIRECTORY, 'font.scm')

  # File for detecting version and data dir of system-installed lilypond
  DETECT_SYSTEM_LILYPOND_FILENAME = File.join(ETC_DIRECTORY, 'detect_system_lilypond.ly')

  # etc/lyp.ly contains lyp:* procedure definitions for loading packages and
  # other support code.
  LYP_LY_LIB_PATH = File.join(ETC_DIRECTORY, 'lyp.ly')
  
  LILYPOND_NOT_FOUND_MSG = "No version of lilypond found.\nTo install lilypond run 'lyp install lilypond'"

  SETTINGS_FILENAME = 'settings.yml'
  
  def self.packages_dir
    ensure_dir(DEFAULT_PACKAGE_DIRECTORY)
  end
  
  def self.lilyponds_dir
    ensure_dir(DEFAULT_LILYPONDS_DIRECTORY)
  end
  
  def self.ext_dir
    ensure_dir(LYP_EXT_DIRECTORY)
  end

  def self.settings_file
    ensure_dir(LYP_DIRECTORY)
    File.join(LYP_DIRECTORY, SETTINGS_FILENAME)
  end
  
  def self.ensure_dir(dir)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    dir
  end

  def self.tmp_filename(suffix = nil)
    fn = (Thread.current.hash * (Time.now.to_f * 1000).to_i % 2**32).to_s(36)
    "#{TMP_ROOT}/#{fn}#{suffix}"
  end
  
  def self.sudo_cp(src, dest)
    cmd = "sudo cp #{src} #{dest}"
    msg = `#{cmd}`
    raise msg unless $?.success?
  end
  
  def self.confirm_action(prompt)
    require 'readline'
    
    response = Readline.readline(prompt)
    ["y", "yes"].include?(response)
  end

  def self.version(v)
    Gem::Version.new(v)
  end

  def self.version_req(r)
    Gem::Requirement.new(r)
  end
end
