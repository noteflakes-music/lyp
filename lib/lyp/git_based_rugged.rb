# A quick-n-dirty rugged swap-in. Since the rugged gem includes a native 
# extension (libgit2), and since traveling-ruby does not yet include an updated
# version of it (the latest is 0.22.0b5 and we need >=0.23.0), we make a 
# compromise, and make a traveling-ruby-based standalone release without 
# rugged, but using plain git in order to install packages. So, users will have 
# to have git installed on their machines.
#
# So here's an absolutely minimal replacement for rugged (just for the 
# functionality we need) wrapping the git command.

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