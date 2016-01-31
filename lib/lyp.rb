$WINDOWS = Gem.win_platform?

# test for existence of 
$rugged_available = begin
  gem 'rugged', '>=0.23.0'
  require 'rugged'
rescue Exception
  nil
end

$git_available = `git --version` rescue nil

unless $rugged_available || $git_available
  raise "Lyp needs git in order to be able to install packages. Please install git and then try again."
end

unless $rugged_available
  require 'lyp/git_based_rugged'
end

require 'tmpdir'
require 'fileutils'
$TMP_DIR = $WINDOWS ? "#{Dir.home}/AppData/Local/Temp" : "/tmp"
$TMP_ROOT = "#{$TMP_DIR}/lyp"
FileUtils.mkdir_p($TMP_ROOT)

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

require File.expand_path("lyp/windows", File.dirname(__FILE__)) if $WINDOWS
