# For Bundler.with_clean_env
require 'bundler'
Bundler.require(:default)
require File.expand_path("./lib/lyp/version", File.dirname(__FILE__))

PACKAGE_NAME = "lyp"
VERSION = Lyp::VERSION

desc "Push gem to rubygems.org"
task :push_gem do
  sh "gem build lyp.gemspec"
  sh "gem build lyp-win.gemspec"
  sh "gem push lyp-#{VERSION}.gem"
  sh "gem push lyp-win-#{VERSION}.gem"
  sh "rm *.gem"
end

desc "Install gem locally"
task :install_gem do
  sh "rm ~/.lyp/bin/*" rescue nil
  sh "gem uninstall -a -x --force lyp"
  sh "gem build lyp.gemspec"
  sh "gem install lyp-#{VERSION}.gem"
  sh "rm lyp-#{VERSION}.gem"
end
