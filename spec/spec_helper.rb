Bundler.setup(:default, :spec)

$spec_dir = File.dirname(__FILE__)
require File.join(File.expand_path($spec_dir), '../lib/lypack')
require 'fileutils'

$packages_dir = Lypack.packages_dir
$lilyponds_dir = Lypack.lilyponds_dir

module Lypack
  def self.packages_dir
    $packages_dir
  end
  
  def self.lilyponds_dir
    $lilyponds_dir
  end
  
  def self.settings_file
    File.join($packages_dir, Lypack::SETTINGS_FILENAME)
  end
end

def with_packages(setup)
  begin
    old_packages_dir = $packages_dir
    $packages_dir = File.expand_path("package_setups/#{setup}", $spec_dir)
    
    # remove settings file
    FileUtils.rm(Lypack.settings_file) if File.file?(Lypack.settings_file)

    yield
  ensure
    # remove settings file
    FileUtils.rm(Lypack.settings_file) if File.file?(Lypack.settings_file)

    $packages_dir = old_packages_dir
  end
end

def with_lilyponds(setup)
  begin
    old_lilyponds_dir = $lilyponds_dir
    $lilyponds_dir = File.expand_path("lilypond_setups/#{setup}", $spec_dir)

    # remove settings file
    FileUtils.rm(Lypack.settings_file) if File.file?(Lypack.settings_file)
    
    yield
  ensure
    # remove settings file
    FileUtils.rm(Lypack.settings_file) if File.file?(Lypack.settings_file)

    $lilyponds_dir = old_lilyponds_dir
  end
end