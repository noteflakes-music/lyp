Bundler.setup(:default, :spec)

$spec_dir = File.dirname(__FILE__)
require File.join(File.expand_path($spec_dir), '../lib/lypack')

$package_setup_dir = Lypack::Loader.packages_dir

module Lypack::Loader
  def self.packages_dir
    $package_setup_dir
  end
end

def with_package_setup(setup)
  begin
    old_setup_dir = $package_setup_dir
    $package_setup_dir = File.expand_path("setups/#{setup}", $spec_dir)
    
    yield
  ensure
    $package_setup_dir = old_setup_dir
  end
end
