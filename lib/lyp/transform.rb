module Lyp::Transform
  class << self
    R = Lyp::DependencyResolver

    def flatten(path, opts = {})
      resolver = Lyp::DependencyResolver.new(path, opts)
      flatten_file(path, opts)
    end

    def flatten_file(path, opts, ctx = {})
      ctx[path] = true

      dir = File.dirname(path)
      src = IO.read(path)

      src.gsub(R::DEP_RE) do
        case $1
        when R::INCLUDE, R::PINCLUDE
          inc_path = find_include_file($2, dir, opts, path)
          "\n%%% #{inc_path}\n#{flatten_file(inc_path, opts, ctx)}\n"
        when R::PINCLUDE_ONCE
          inc_path = find_include_file($2, dir, opts, path)
          if ctx[inc_path]
            ""
          else
            "\n%%% #{inc_path}\n#{flatten_file(inc_path, opts, ctx)}\n"
          end
        else
          $~
        end
      end
    end

    def find_include_file(ref, dir, opts, source_path)
      search_paths = [dir]
      search_paths += opts[:include_paths] if opts[:include_paths]

      search_paths.each do |path|
        full_path = File.expand_path(ref, path)
        return full_path if File.file?(full_path)
      end

      raise "Missing include file #{ref} specified in #{source_path}"
    end
  end
end
