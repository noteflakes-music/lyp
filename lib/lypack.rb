module Lypack
  DEFAULT_PACKAGE_DIRECTORY = File.expand_path('~/.lypack/packages')

  def self.packages_dir
    DEFAULT_PACKAGE_DIRECTORY
  end
  
end

%w{template resolver wrapper}.each do |f|
  require File.expand_path("lypack/#{f}", File.dirname(__FILE__))
end
