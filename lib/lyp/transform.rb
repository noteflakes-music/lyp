require 'fileutils'

module Lyp::Transform
  class << self
    R = Lyp::DependencyResolver

    def flatten(path, ctx = {})
      ctx[path] = true

      dir = File.dirname(path)
      src = IO.read(path)

      src.gsub(R::DEP_RE) do
        inc_path = File.expand_path($2, dir)
        case $1
        when R::INCLUDE, R::PINCLUDE
          "\n%%% #{inc_path}\n#{flatten(inc_path, ctx)}\n"
        when R::PINCLUDE_ONCE
          if ctx[inc_path]
            ""
          else
            "\n%%% #{inc_path}\n#{flatten(inc_path, ctx)}\n"
          end
        else
          $~
        end
      end
    end
  end
end
