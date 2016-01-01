module Lypack::Package
  class << self
    def list(pattern = nil)
      packages = Dir["#{Lypack::DEFAULT_PACKAGE_DIRECTORY}/*"].map do |p|
        File.basename(p)
      end
      
      if pattern
        packages.select! {|p| p =~ /#{pattern}/}
      end
      
      packages.sort
    end
  end
end