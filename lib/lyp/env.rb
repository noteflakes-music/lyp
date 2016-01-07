module Lyp::ENV
  class << self
    PROFILE_FILES = %w{
      .profile .bash_profile .bash_login .bashrc .zshenv .zshrc .mkshrc
    }.map {|fn| File.join(Dir.home, fn)}

    LYPACK_LOAD_CODE = <<EOF

[[ ":${PATH}:" == *":${HOME}/.lyp/bin:"* ]] || PATH="$HOME/.lyp/bin:$PATH"
EOF

    def install!
      # Install lyp in environment

      PROFILE_FILES.each do |fn|
        next unless File.file?(fn)
        unless IO.read(fn) =~ /\.lyp\/bin/
          begin
            File.open(fn, 'a') {|f| f << LYPACK_LOAD_CODE}
          rescue
            # ignore
          end
        end
      end
    end
    
    def installed?
      ":#{::ENV['PATH']}:" =~ /#{Lyp::LYPACK_BIN_DIRECTORY}/
    end
  end
end

