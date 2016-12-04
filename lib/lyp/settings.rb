module Lyp::Settings
  class << self
    def load
      req_ext 'yaml'
      @settings = YAML.load(IO.read(Lyp.settings_file)) rescue {}
    end

    def save
      req_ext 'yaml'
      File.open(Lyp.settings_file, 'w+') {|f| f << YAML.dump(@settings)}
    end

    def [](path)
      h = load
      while path =~ /^([^\/]+)\/(.+)$/
        h = h[$1.to_sym] ||= {}
        path = $2
      end

      h[path.to_sym]
    end

    def []=(path, value)
      h = load
      while path =~ /^([^\/]+)\/(.+)$/
        h = h[$1.to_sym] ||= {}
        path = $2
      end

      h[path.to_sym] = value
      save
      value
    end

    def get_value(path, default = nil)
      req_ext 'yaml'
      v = self[path]
      v ? YAML.load(v) : default
    end

    def set_value(path, value)
      req_ext 'yaml'
      self[path] = YAML.dump(value)
    end
  end
end
