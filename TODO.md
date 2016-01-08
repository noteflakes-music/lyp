- Rethink lyp installation:
  - lyp should be able to install itself in ~/.lyp
  - so we need to:
  
    - have ~/.lyp/bin in $PATH
    - copy lyp binaries (lyp and lilypond) to ~/.lyp/bin
  
  - we have two use cases:
    - lyp is installed as a gem
    - lyp is installed as a release (packaged with traveling-ruby)
    - detecting lyp as a release: path of script is .../lib/app/bin/lyp
      
  - installing from lyp gem:
    - symlink gem binaries to ~/.lyp/bin/
    
  - installing form lyp release:
    - copy release/lib to ~/.lyp/lib
    - write custom wrapper scripts (for both lyp and lilypond) to ~/.lyp/bin/
    
    - a wrapper script looks like this:
      
      #!/bin/bash
      set -e

      LYP_DIR="`cd ~/.lyp && pwd`"

      # Tell Bundler where the Gemfile and gems are.
      export BUNDLE_GEMFILE="$LYP_DIR/lib/vendor/Gemfile"
      unset BUNDLE_IGNORE_CONFIG

      exec "$LYP_DIR/lib/ruby/bin/ruby" -rbundler/setup -rreadline -I$LYP_DIR/lib/app/lib "$LYP_DIR/lib/app/bin/lyp" "$@"

