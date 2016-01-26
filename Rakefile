# For Bundler.with_clean_env
require 'bundler/setup'
require File.expand_path("./lib/lyp/version", File.dirname(__FILE__))

PACKAGE_NAME = "lyp"
VERSION = Lyp::VERSION
TRAVELING_RUBY_VERSION = "20150715-2.2.2"
NOKOGIRI_VERSION = "1.6.6.2"
RUGGED_VERSION = "0.21.4"

NOKOGIRI_POSTFIX = "nokogiri-#{NOKOGIRI_VERSION}"
RUGGED_POSTFIX = "rugged-#{RUGGED_VERSION}"

TRAVELING_RUBY_BASE_URL = "http://d6r77u77i8pq3.cloudfront.net/releases"
PACKAGING_BASE_PATH = "packaging/traveling-ruby"

task :default => [:package]

desc "Package your app"
task :package => [:download, 'package:linux:x86', 'package:linux:x86_64', 'package:osx']

desc "Push gem to rubygems.org"
task :push_gem do
  sh "gem build lyp.gemspec"
  sh "gem push lyp-#{VERSION}.gem"
  sh "rm lyp-#{VERSION}.gem"
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
      "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-linux-x86-#{NOKOGIRI_POSTFIX}.tar.gz"
      # "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-linux-x86-#{RUGGED_POSTFIX}.tar.gz"
    ] do
      create_package("linux-x86")
    end

    desc "Package your app for Linux x86_64"
    task :x86_64 => [:bundle_install, 
      "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz",
      "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-linux-x86_64-#{NOKOGIRI_POSTFIX}.tar.gz"
      # "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-linux-x86_64-#{RUGGED_POSTFIX}.tar.gz"
    ] do
      create_package("linux-x86_64")
    end
  end

  desc "Package your app for OS X"
  task :osx => [:bundle_install, 
    "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-osx.tar.gz",
    "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-osx-#{NOKOGIRI_POSTFIX}.tar.gz"
    # "#{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-osx-#{RUGGED_POSTFIX}.tar.gz"
  ] do
    create_package("osx")
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
  %w{linux-x86 linux-x86_64 osx}.each do |platform|
    download_runtime(platform)
    download_native_extension(platform, NOKOGIRI_POSTFIX)
    # download_native_extension(platform, RUGGED_POSTFIX)
  end
end

def create_package(target)
  package_path = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
  sh "rm -rf #{package_path}"
  sh "mkdir #{package_path}"
  sh "mkdir -p #{package_path}/lib/app"
  sh "cp -r bin #{package_path}/lib/app/"
  sh "cp -r lib #{package_path}/lib/app/"
  sh "mkdir #{package_path}/lib/ruby"
  sh "tar -xzf #{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_path}/lib/ruby"

  sh "mkdir -p #{package_path}/bin"
  sh "cp bin/release_wrapper_lyp.sh #{package_path}/bin/lyp"
  sh "cp bin/release_wrapper_lilypond.sh #{package_path}/bin/lilypond"

  sh "cp -pR packaging/vendor #{package_path}/lib/"
  sh "cp Gemfile Gemfile.lock #{package_path}/lib/vendor/"
  sh "mkdir #{package_path}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_path}/lib/vendor/.bundle/config"
  sh "tar -xzf #{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-#{target}-#{NOKOGIRI_POSTFIX}.tar.gz " +
      "-C #{package_path}/lib/vendor/ruby"
  # sh "tar -xzf #{PACKAGING_BASE_PATH}-#{TRAVELING_RUBY_VERSION}-#{target}-#{RUGGED_POSTFIX}.tar.gz " +
  #     "-C #{package_path}/lib/vendor/ruby"
  if !ENV['DIR_ONLY']
    sh "mkdir -p releases"
    sh "tar -czf releases/#{package_path}.tar.gz #{package_path}"
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

# desc "Create a new release"
# task :release do
#   sh "git tag v#{VERSION} && git push --tags"
#   sh "github-release release -u noteflakes -r lyp -t v#{VERSION} -n \"\""
# end