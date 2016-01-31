- Windows
  - we will need to find a way to compile rugged and include it in a windows release.
  - if not, the alternative is too problematic: installing git itself on windows is not such a pleasant experience, and it requires quite a bit of fudging around, including releasing a separate gem version which does not 
  - meanwhile we can work with the git repository on a Windows machine, and get it to work from there.
  - once we get rugged to work, we might be able to package it into a Windows executable using https://github.com/larsch/ocra/.

- Improve missing dependency error message
  - Track the locations of \require commands
  - Change text to:
  
    Missing package dependency "assert" in test.ly:2:1
    
      \require "assert"
      
    You can install any mis sing package dependencies by running:
    
      'lyp resolve test.ly'
      
- Check lilypond error on requiring the same package using different version constraints (\require "assert" , \require "assert>=0.1.3") in the same file.

- Specs for CLI commands.

- Specs for lilypond command.


