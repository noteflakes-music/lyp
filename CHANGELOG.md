# Version 1.1.0 2016-12-04

- Improve performance by loading dependencies only when needed.
- Implement `lyp update` and `lyp install -u` commands (#33).

# Version 1.0.3 2016-11-30

- Refactor Lilypond option parsing.
- Refactor version and version requirement construction.

# Version 1.0.2 2016-11-28

- Add support for finalizers in package Scheme API.
- Fix ARGV parsing when filename includes hyphen.
- Better documentation for Ruby extension API.

## Version 1.0.1 2016-08-31

- Better error reporting when installing packages.
- Add appropriate `\paper` preamble when `--snippet` option is specified (#29).
- Improve lilypond option processing by allowing a string of single-letter options, e.g. `lilypond -FncO`.
- Add `--force-version` lilypond option for selecting lilypond version according to version statement in user file (#28).

## Version 1.0.0 2016-06-29

- Fix `\pcondIncludeOnce`.
- Implement flatten command (#26).

## Version 0.3.9 2016-06-27

- Add `--auto-install-deps` lilypond option for automatically installing missing dependencies (#25).
- Add `--snippet` option to lilypond for creating cropped png images (#24).
- Add `--dev` option for installing development packages (#23).
- Raise error in mismatching require version clauses in same file (#12).
- Add automatic periodic checking for new unstable versions of lilypond (#7).

## Version 0.3.8 2016-06-14

- Fix behavior when `-dhelp` switch is specified.
- Add custom `-c, --cropped` switch for cropped lilypond output (shorthand for `-dbackend=eps -daux-files=#f`).
- Fix installing font packages with nested font directories.

## Version 0.3.7 2016-06-02

- Update package URLs (packages are now placed in the [lyp-packages](https://github.com/lyp-packages) organisation).
- Run *-test.ly as well as *_test.ly files.
- Show assert summary if assert package was loaded.
- Add `\pcondInclude`, `\pcondIncludeOnce` commands for conditional includes.

## Version 0.3.6 2016-03-08

- Add `-r/--require` command line for preloading packages (#19).
- Rewrite `\require`, `\pinclude`, `\pincludeOnce` commands for better compatibility with legacy lilypond code.

## Version 0.3.5 2016-03-01

- Ask for confirmation before patching and installing fonts in system-installed lilyponds.

## Version 0.3.4 2016-02-29

- Make lyp and lilypond binaries load faster.
- Fix installing fonts for system-installed lilyponds (#18)
- Show package description on search.

## Version 0.3.3 2016-02-21

- Add support for including ruby extensions in packages.
- Rewrite package scheme interface, \pinclude now properly supports relative paths when doing nested includes, on both Lilypond 2.18 and 2.19.

## Version 0.3.2 2016-02-20

- Fix --raw command line option in lilypond binary script.
- Wrap also files without package dependencies, in order to provide the \pinclude, etc. functionality. This can be overriden using the --raw command line option.

## Version 0.3.1 2016-02-04

- Accept stdin input for lilypond.
- Show `install self` warning only for standalone releases.

## Version 0.3.0 2016-02-03

- Improve `lyp install self` behavior on all platforms.
- Add standalone package for Windows.

## Version 0.2.3 2016-02-02

- Windows support!

## Version 0.2.2 2016-01-31

- Improve README documentation.
- Fix lilypond wrapper to not eat stock lilypond options (#10).
- Add --env, --use, --install options to lilypond wrapper, lyp test, lyp compile commands.
- Remove nokogiri dependency.
- Fix behaviour when no version of lilypond is installed.
- Various improvements to command line interface.

## Version 0.2.1 2016-01-28

- Packages tests can now use `\require "<package name>:<relative path>"` syntax in tests to make sure tests work anywhere. For an example see the [assert package](https://github.com/noteflakes/lyp-assert).
- Complete rewrite of package scheme interface, now tested using the assert package.

## Version 0.2.0 2016-01-27

- Rename `lyp-*` variables to `lyp:*`.
- Add -t switch to `lyp install` to test a package after installation.
- Fix uninstalling non-versioned packages.
- Add `lyp test` command for testing packages.
- Fix `lyp install` command.
- Fix and enhance `lyp compile` command.
- Fix `lyp uninstall self` command.
- Accept `scheme-sandbox` argument in lilypond wrapper (#8).
- Add support for installing custom fonts from packages (starting from lilypond 2.18.2), and automatic patching of lilypond versions lower than 2.19.12 in order to support custom fonts.

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
