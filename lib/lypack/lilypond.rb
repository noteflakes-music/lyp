module Lypack::Lilypond
  class << self
    def compile(argv)
      fn = Lypack.wrap(argv.pop)
      argv << fn
      exec("lilypond #{argv.join(' ')}")
    end
  end
end