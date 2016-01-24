## Version 0.1.4 2016-01-24

- Fix lyp-current-package-dir for local (development) packages.

## Version 0.1.3 2016-01-24

- Do not list lilypond script in Gem bindir (#6).
- Add lyp-* variables, \pinclude command for including files from within packages.
- Add [installation script](https://github.com/noteflakes/lyp#installation).

## Version 0.1.2 2016-01-18

- Add stand-alone release using [traveling-ruby](https://github.com/phusion/traveling-ruby).

## Version 0.1.0 2016-01-13

- Improve output of `lyp list` (group by package).
- Display warning, do not exit if lyp self installation test fails.
- Fix install/uninstall using git URL.
- Add support for installing a package from local files:

    lyp install mypack@dev:~/repo/mypack

- Add resolve command to install all dependencies required for a given .ly file.
- Add deps command to show required dependencies for a given .ly file.
- Ampersand can be ommited when specifying version constraints, e.g. lilypond>=2.19.31 etc.

## Version 0.0.5 2016-01-11

- Add which command (for both packages and lilypond)
- Add package uninstall command
- Check validity of default/current lilypond before invoking it
- Install highest versioned tag if version is not specified
- CLI now uses thor for prettier code
- Fix bin/lilypond to work with multiple arguments

## Version 0.0.4 2016-01-10

- Search for simple package name (non-url) in [lyp-index](https://github.com/noteflakes/lyp-index)
- Add support for `lyp search lilypond@<version|stable|unstable|latest>`
- Implement package installation
- Move lyp repository to [noteflakes org](https://github.com/noteflakes/lyp)

## Version 0.0.3 2016-01-08

- Add uninstall lyp command
- Add install lyp command
- Cleanup temp files in /tmp after installing lilypond
- Add support for 'lyp install lilypond' (install latest stable version)

## Version 0.0.2 2016-01-07

- Install, uninstall and switch between different versions of lilypond
- Resolve package dependencies in user files, and invoke lilypond
