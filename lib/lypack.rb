module Lypack
  DEFAULT_PACKAGE_DIRECTORY = File.expand_path('~/.lypack/packages')

  def self.packages_dir
    DEFAULT_PACKAGE_DIRECTORY
  end
  
end

require 'lypack/resolver'
require 'lypack/template'