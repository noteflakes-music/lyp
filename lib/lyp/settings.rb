require 'yaml'

module Lyp::Settings
  class << self
    def get
      YAML.load(IO.read(Lyp.settings_file)) rescue {}
    end
    
    def set(o)
      File.open(Lyp.settings_file, 'w+') {|f| f << YAML.dump(o)}
    end
    
    def [](path)
      h = get
      while path =~ /^([^\/]+)\/(.+)$/
        h = h[$1.to_sym] ||= {}
        path = $2
      end
      
      h[path.to_sym]
    end
    
    def []=(path, value)
      h = settings = get
      while path =~ /^([^\/]+)\/(.+)$/
        h = h[$1.to_sym] ||= {}
        path = $2
      end
      
      h[path.to_sym] = value
      
      set(settings)
      
      value
    end
  end
end