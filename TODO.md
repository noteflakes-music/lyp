- Add --install, --env options to `lilypond` wrapper

  --env to force version from LILYPOND_VERSION environment variable
  --install for installing version if missing
  
  `LILYPOND_VERSION=2.19.13 lilypond --env ...`
  
- Add --install, --env options to `lyp compile`

  `LILYPOND_VERSION=2.18.2 lyp compile --env --install ...`
  
- Add --use parameter to lilypond wrapper

  `lilypond --use 2.19.33 --install myfile.ly`

- Check functioning of lyp test, lyp compile, lilypond commands when no version of lilypond is available.

- Check lilypond error on requiring the same package using different version constraints (\require "assert" , \require "assert>=0.1.3") in the same file.