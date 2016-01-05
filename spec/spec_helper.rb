Bundler.setup(:default, :spec)

$spec_dir = File.dirname(__FILE__)
require File.join(File.expand_path($spec_dir), '../lib/lypack')
require 'fileutils'

$package_setup_dir = Lypack.packages_dir

module Lypack
  def self.packages_dir
    $package_setup_dir
  end
  
  def self.settings_file
    File.join($package_setup_dir, Lypack::SETTINGS_FILENAME)
  end
end

def with_package_setup(setup)
  begin
    old_setup_dir = $package_setup_dir
    $package_setup_dir = File.expand_path("setups/#{setup}", $spec_dir)
    
    # remove settings file
    FileUtils.rm(Lypack.settings_file) if File.file?(Lypack.settings_file)

    yield
  ensure
    # remove settings file
    FileUtils.rm(Lypack.settings_file) if File.file?(Lypack.settings_file)
    $package_setup_dir = old_setup_dir
  end
end
