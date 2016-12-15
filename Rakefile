# For Bundler.with_clean_env
require 'bundler'
Bundler.require(:default)
require File.expand_path("./lib/lyp/version", File.dirname(__FILE__))

PACKAGE_NAME = "lyp"
VERSION = Lyp::VERSION
TRAVELING_RUBY_VERSION = "20150715-2.2.2"

TRAVELING_RUBY_BASE_URL = "http://d6r77u77i8pq3.cloudfront.net/releases"
DIST_DIR = "dist"
VENDOR_DIR = "#{DIST_DIR}/vendor"
TRAVELING_RUBY_BASE_PATH = "#{VENDOR_DIR}/traveling-ruby/traveling-ruby-#{TRAVELING_RUBY_VERSION}"
RELEASE_DIR = "#{DIST_DIR}/release"

task :default => [:release]

desc "Package release files"
task :release => %w{
  download
  release:linux:x86
  release:linux:x86_64
  release:osx
  release:win32
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
end

namespace :release do
  namespace :linux do
    desc "Package your app for Linux x86"
    task :x86 => [:bundle_install,
      "#{TRAVELING_RUBY_BASE_PATH}-linux-x86.tar.gz",
    ] do
      create_package("linux-x86")
    end

    desc "Package your app for Linux x86_64"
    task :x86_64 => [:bundle_install,
      "#{TRAVELING_RUBY_BASE_PATH}-linux-x86_64.tar.gz",
    ] do
      create_package("linux-x86_64")
    end
  end

  desc "Package your app for MacOS"
  task :osx => [:bundle_install,
    "#{TRAVELING_RUBY_BASE_PATH}-osx.tar.gz",
  ] do
    create_package("osx")
  end

  desc "Package your app for Windows x86"
  task :win32 => [:bundle_install, "#{TRAVELING_RUBY_BASE_PATH}-win32.tar.gz"] do
    puts "create_package win32"
    create_package("win32", :windows)
  end

  desc "Install gems to local directory"
  task :bundle_install do
    if RUBY_VERSION !~ /^2\.2\./
      abort "You can only 'bundle install' using Ruby 2.2, because that's what Traveling Ruby uses."
    end
    sh "rm -rf #{DIST_DIR}/tmp"
    sh "mkdir #{DIST_DIR}/tmp"
    sh "cp Gemfile Gemfile.lock #{DIST_DIR}/tmp/"
    Bundler.with_clean_env do
      sh "cd #{DIST_DIR}/tmp && env BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without spec:not_in_release"
    end
    sh "rm -rf #{DIST_DIR}/tmp"
    sh "rm -f #{DIST_DIR}/vendor/*/*/cache/*"
    sh "rm -f #{DIST_DIR}/vendor/*/*/cache/*"
    sh "rm -rf #{DIST_DIR}/vendor/ruby/*/extensions"

    # also remove any spec or test dirs
    sh "rm -rf #{DIST_DIR}/vendor/ruby/*/gems/*/test"
    sh "rm -rf #{DIST_DIR}/vendor/ruby/*/gems/*/spec"

    sh "find #{DIST_DIR}/vendor/ruby/*/gems -name '*.so' | xargs rm -f"
    sh "find #{DIST_DIR}/vendor/ruby/*/gems -name '*.bundle' | xargs rm -f"
    sh "find #{DIST_DIR}/vendor/ruby/*/gems -name '*.o' | xargs rm -f"
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

  puts "create_package #{package_path}"

  sh "rm -rf #{package_path}/"
  sh "mkdir #{package_path}"
  sh "mkdir -p #{package_path}/lib/app"
  sh "cp -r bin #{package_path}/lib/app/"
  sh "cp -r lib #{package_path}/lib/app/"
  sh "mkdir #{package_path}/lib/ruby"
  sh "tar -xzf #{TRAVELING_RUBY_BASE_PATH}-#{target}.tar.gz -C #{package_path}/lib/ruby"

  sh "mkdir -p #{package_path}/bin"

  if os_type == :unix
    sh "cp #{VENDOR_DIR}/lyp/release_wrapper_lyp.sh #{package_path}/bin/lyp"
    sh "cp #{VENDOR_DIR}/lyp/release_wrapper_lilypond.sh #{package_path}/bin/lilypond"
  else
    sh "cp #{VENDOR_DIR}/lyp/release_wrapper_lyp.bat #{package_path}/bin/lyp.bat"
    sh "cp #{VENDOR_DIR}/lyp/release_wrapper_lilypond.bat #{package_path}/bin/lilypond.bat"
  end

  # sh "cp -pR #{DIST_DIR}/vendor #{package_path}/lib/"
  sh "mkdir #{package_path}/lib/vendor"
  sh "cp -pR #{DIST_DIR}/vendor/lyp #{package_path}/lib/vendor/"
  sh "cp -pR #{DIST_DIR}/vendor/ruby #{package_path}/lib/vendor/"

  sh "cp Gemfile Gemfile.lock #{package_path}/lib/vendor/"
  sh "mkdir #{package_path}/lib/vendor/.bundle"
  sh "cp #{VENDOR_DIR}/lyp/bundler-config #{package_path}/lib/vendor/.bundle/config"
  if !ENV['DIR_ONLY']
    sh "mkdir -p #{RELEASE_DIR}"
    if os_type == :unix
      sh "tar -czf #{RELEASE_DIR}/#{package_path}.tar.gz #{package_path}"
    else
      sh "zip -9r #{RELEASE_DIR}/#{package_path}.zip #{package_path}"
    end
    sh "rm -rf #{package_path}/"
  end
end

def download_runtime(platform)
  fn = "#{TRAVELING_RUBY_BASE_PATH}-#{platform}.tar.gz"
  return if File.file?(fn)

  url = "#{TRAVELING_RUBY_BASE_URL}/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{platform}.tar.gz"
  sh "curl -L  --fail -o #{fn} #{url}"
end

def download_native_extension(platform, gem_name_and_version)
  fn = "#{TRAVELING_RUBY_BASE_PATH}-#{platform}-#{gem_name_and_version}.tar.gz"
  return if File.file?(fn)
  url = "#{TRAVELING_RUBY_BASE_URL}/traveling-ruby-gems-#{TRAVELING_RUBY_VERSION}-#{platform}/#{gem_name_and_version}.tar.gz"
  sh "curl -L --fail -o #{fn} #{url}"
end
