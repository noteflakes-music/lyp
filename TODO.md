- Windows
  - find a way to compile rugged and include it in a windows release.
  - once we get rugged to work, we might be able to package it into a Windows executable using https://github.com/larsch/ocra/.

- Improve missing dependency error message
  - Track the locations of \require commands
  - Change text to:
  
    Missing package dependency "assert" in test.ly:2:1
    
      \require "assert"
      
    You can install any mis sing package dependencies by running:
    
      'lyp resolve test.ly'
      
- Specs for CLI commands.

- Specs for lilypond command.


