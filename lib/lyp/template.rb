module Lyp
  class Template
    EMIT_DELIMITER = '`'.freeze
    EMIT_RE = /#{EMIT_DELIMITER}(((?!#{EMIT_DELIMITER}).)*)#{EMIT_DELIMITER}/m

    INTERPOLATION_START = "{{".freeze
    INTERPOLATION_END = "}}".freeze
    INTERPOLATION_RE = /#{INTERPOLATION_START}((?:(?!#{INTERPOLATION_END}).)*)#{INTERPOLATION_END}/m

    ESCAPED_QUOTE = '\\"'.freeze
    QUOTE = '"'.freeze
  
    # From the metaid gem
    def metaclass; class << self; self; end; end

    def initialize(templ)
      templ = templ.gsub(EMIT_RE) {|m| convert_literal($1)}
      method_str = <<EOF
      define_method(:render) do |_ = {}, env = {}|
        __buffer__ = env[:buffer] ||= ''
        __emit__ = env[:emit] ||= lambda {|s| __buffer__ << s}
        __render_l__ = env[:render] ||= lambda {|n, o| Template.render(n, o, env)}
        metaclass.instance_eval "define_method(:__render__) {|n, o| __render_l__[n, o]}"
        begin
          #{templ}
        end
        __buffer__
      end
EOF

      metaclass.instance_eval method_str
    end
  
    def convert_literal(s)
      # look for interpolated values, wrap them with #{}
      s = s.inspect.gsub(INTERPOLATION_RE) do
        code = $1.gsub(ESCAPED_QUOTE, QUOTE) 
        "\#{#{code}}"
      end
      "__emit__[#{s}]"
    end
    
    # Global template registry
    @@templates = {}

    def self.load_templates(path)
      Dir["#{path}/*.rb"].each {|fn| set(File.basename(fn), IO.read(fn))}
    end
    
    def self.set(name, templ)
      @@templates[name.to_sym] = new(templ)
    end
    
    def self.render(name, arg = {}, env = {})
      raise unless @@templates[name.to_sym]
      @@templates[name.to_sym].render(arg, env)
    end
  end
end