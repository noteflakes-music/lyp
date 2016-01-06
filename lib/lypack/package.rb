module Lypack::Package
  class << self
    
    def list(pattern = nil)
      packages = Dir["#{Lypack.packages_dir}/*"].map do |p|
        File.basename(p)
      end
      
      if pattern
        packages.select! {|p| p =~ /#{pattern}/}
      end
      
      packages.sort do |x, y|
        x =~ Lypack::PACKAGE_RE; x_package, x_version = $1, $2
        y =~ Lypack::PACKAGE_RE; y_package, y_version = $1, $2

        x_version = x_version && Gem::Version.new(x_version)
        y_version = y_version && Gem::Version.new(y_version)

        if x_package == y_package
          x_version <=> y_version
        else
          x_package <=> y_package
        end
      end
    end
  end
end