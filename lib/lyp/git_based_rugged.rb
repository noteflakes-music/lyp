# A quick-n-dirty rugged swap-in

puts "git_based_rugged"

module Rugged
  class Repository
    def self.clone_at(url, path)
      `git clone -q \"#{url}\" \"#{path}\"`
      new(path)
    end
    
    def initialize(path)
      @path = path
      exec('status')
    end
    
    Ref  = Struct.new(:name)

    def head
      h = exec("show-ref --head").lines.map {|r| r =~ /^(\S+)\sHEAD$/ && $1}[0]
      Ref.new(h)
    end
    
     
    def checkout(ref, opts)
      # strategy: :force
      exec("checkout -qf #{ref}")
    end
    
    def tags
      exec("tag").lines.map {|l| Ref.new(l.chomp)}
    end 

    def exec(cmd)
      `cd #{@path} && git #{cmd}`
    end
  end
end