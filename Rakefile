# For Bundler.with_clean_env
require 'bundler/setup'
require File.expand_path("./lib/lyp/version", File.dirname(__FILE__))

PACKAGE_NAME = "lyp"
VERSION = Lyp::VERSION
TRAVELING_RUBY_VERSION = "20150715-2.2.2"

TRAVELING_RUBY_BASE_URL = "http://d6r77u77i8pq3.cloudfront.net/releases"
PACKAGING_BASE_PATH = "packaging/traveling-ruby"

task :default => [:package]

desc "Package your app"
task :package => %w{
  download
  package:linux:x86
  package:linux:x86_64
  package:osx
  package:win32
}

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
  puts "Finish installation by running 'lyp install self'"
end


namespace :package do
  namespace :linux do
    desc "Package your app for Linux x86"
    task :x86 => [:bundle_install, 
      "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz",
    ] do
      create_package("linux-x86")
    end

    desc "Package your app for Linux x86_64"
    task :x86_64 => [:bundle_install, 
      "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz",
    ] do
      create_package("linux-x86_64")
    end
  end

  desc "Package your app for OS X"
  task :osx => [:bundle_install, 
    "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-osx.tar.gz",
  ] do
    create_package("osx")
  end
  
  desc "Package your app for Windows x86"
  task :win32 => [:bundle_install, "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-win32.tar.gz"] do
    puts "create_package win32"
    create_package("win32", :windows)
  end

  desc "Install gems to local directory"
  task :bundle_install do
    if RUBY_VERSION !~ /^2\.2\./
      abort "You can only 'bundle install' using Ruby 2.2, because that's what Traveling Ruby uses."
    end
    sh "rm -rf packaging/tmp"
    sh "mkdir packaging/tmp"
    sh "cp Gemfile Gemfile.lock packaging/tmp/"
    Bundler.with_clean_env do
      sh "cd packaging/tmp && env BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without spec:not_in_release"
    end
    sh "rm -rf packaging/tmp"
    sh "rm -f packaging/vendor/*/*/cache/*"
    sh "rm -f packaging/vendor/*/*/cache/*"
    sh "rm -rf packaging/vendor/ruby/*/extensions"

    # also remove any spec or test dirs
    sh "rm -rf packaging/vendor/ruby/*/gems/*/test"
    sh "rm -rf packaging/vendor/ruby/*/gems/*/spec"

    sh "find packaging/vendor/ruby/*/gems -name '*.so' | xargs rm -f"
    sh "find packaging/vendor/ruby/*/gems -name '*.bundle' | xargs rm -f"
    sh "find packaging/vendor/ruby/*/gems -name '*.o' | xargs rm -f"
  end
end

desc "Download rubys & native extensions"
task :download do
  %w{linux-x86 linux-x86_64 osx win32}.each do |platform|
    download_runtime(platform)
  end
end

def create_package(target, os_type = :unix)
  package_path = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
  sh "rm -rf #{package_path}"
  sh "mkdir #{package_path}"
  sh "mkdir -p #{package_path}/lib/app"
  sh "cp -r bin #{package_path}/lib/app/"
  sh "cp -r lib #{package_path}/lib/app/"
  sh "mkdir #{package_path}/lib/ruby"
  sh "tar -xzf #{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_path}/lib/ruby"

  sh "mkdir -p #{package_path}/bin"
  
  if os_type == :unix
    sh "cp packaging/release_wrapper_lyp.sh #{package_path}/bin/lyp"
    sh "cp packaging/release_wrapper_lilypond.sh #{package_path}/bin/lilypond"
  else
    sh "cp packaging/release_wrapper_lyp.bat #{package_path}/bin/lyp.bat"
    sh "cp packaging/release_wrapper_lilypond.bat #{package_path}/bin/lilypond.bat"
  end

  sh "cp -pR packaging/vendor #{package_path}/lib/"
  sh "cp Gemfile Gemfile.lock #{package_path}/lib/vendor/"
  sh "mkdir #{package_path}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_path}/lib/vendor/.bundle/config"
  if !ENV['DIR_ONLY']
    sh "mkdir -p releases"
    if os_type == :unix
      sh "tar -czf releases/#{package_path}.tar.gz #{package_path}"
    else
      sh "zip -9r releases/#{package_path}.zip #{package_path}"
    end
    sh "rm -rf #{package_path}"
  end
end

def download_runtime(platform)
  fn = "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-#{platform}.tar.gz"
  return if File.file?(fn)

  url = "#{TRAVELING_RUBY_BASE_URL}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{platform}.tar.gz"
  sh "curl -L  --fail -o #{fn} #{url}"
end

def download_native_extension(platform, gem_name_and_version)
  fn = "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-#{platform}-#{gem_name_and_version}.tar.gz"
  return if File.file?(fn)
  url = "#{TRAVELING_RUBY_BASE_URL}/traveling-ruby-gems-#{TRAVELING_RUBY_VERSION}-#{platform}/#{gem_name_and_version}.tar.gz"
  sh "curl -L --fail -o #{fn} #{url}"
end
