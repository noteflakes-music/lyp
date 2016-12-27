<p align="center">
  <a href="https://travis-ci.org/noteflakes/lyp"><img src="https://travis-ci.org/noteflakes/lyp.svg?branch=master"></a>
</p>
<p align="center">
  <a href="https://github.com/lyp-packages/index#readme">The lyp package index</a>
</p>

# lyp - The Lilypond Swiss Army Knife

Use lyp to install and manage packages for [Lilypond](http://lilypond.org/), install and manage multiple versions of Lilypond on your machine, and improve your Lilypond workflow.

__Code reuse__: lyp lets you install packages that act as Lilypond code libraries and can be used to enhance your Lilypond files with additional functionality. Packages can depend on other packages. Lyp resolves both direct and transitive package dependencies, and automatically selects the correct version to use for each package.

__No hassle Lilypond installation__: With lyp you can also install any version of Lilypond on your machine with a single command, without having to visit the Lilypond website, clicking a link and then copying files around. In addition, lyp lets you switch between multiple versions of Lilypond and always keep your machine up to date with the latest version.

__Tools for power users__: with lyp you can [benchmark](#lyp-benchmark) and compare the performance of multiple versions of Lilypond, [flatten](#lyp-flatten) include files, automatically recompile [modified source files](#lyp-watch), and [automatically install](#lyp-compile) package dependencies or any required version of Lilypond.

## Table of contents

- [Installation](#installation)
  - [System requirements](#system-requirements)
  - [Installing lyp as a Ruby gem](#installing-lyp-as-a-ruby-gem)
  - [Installing lyp as a standalone release](#installing-lyp-as-a-standalone-release)
  - [Manually installing releases](manually-installing-releases)
  - [Uninstalling lyp](#uninstalling-lyp)
- [How lyp works](#how-lyp-works)
- [Working with packages](#working-with-packages)
  - [What is a package?](#what-is-a-package)
  - [Installing packages](#installing-packages)
  - [Automatic package installation](#automatic-package-installation)
  - [Package references](#package-references)
  - [Version specifiers](#version-specifiers)
  - [Using packages](#using-packages)
- [Developing packages](#developing-packages)
  - [The package interface](#the-package-interface)
  - [Including files](#including-files)
  - [Scheme interface](#scheme-interface)
  - [Including fonts](#including-fonts)
  - [Extending lyp](#extending-lyp)
  - [Testing packages](#testing-packages)
  - [Publishing packages](#publishing-packages)
- [Installing and Using Lilypond](#installing-and-using-lilypond)
  - [Installing/uninstalling a version of Lilypond](#installinguninstalling-a-version-of-lilypond)
  - [Showing the list of installed Lilypond versions](#showing-the-list-of-installed-lilypond-versions)
  - [Showing available Lilypond versions](#Showing-available-lilypond-versions)
  - [Switching between Lilypond versions](#switching-between-lilypond-versions)
  - [Running Lilypond](#running-lilypond)
- [Command Reference](#command-reference)
  - [lyp accelerate](#lyp-accelerate) - rewrite gem binaries for faster execution
  - [lyp benchmark](#lyp-benchmark) - benchmark installed versions of Lilypnd
  - [lyp cleanup](#lyp-cleanup) - cleanup temporary files
  - [lyp compile](#lyp-compile) - compile Lilypond source files
  - [lyp deps](#lyp-deps) - show dependencies for a given source file
  - [lyp exec](#lyp-exec) - execute a Lilypond script
  - [lyp flatten](#lyp-flatten) - flatten a Lilypond project by inlining includes
  - [lyp install](#lyp-install) - install package or Lilypond
  - [lyp list](#lyp-list) - list installed packages or Lilyponds
  - [lyp resolve](#lyp-resolve) - resolve and install dependencies for a given source file
  - [lyp search](#lyp-search) - search for packages or Lilyponds
  - [lyp test](#lyp-test) - run Lilypond test files
  - [lyp uninstall](#lyp-uninstall) - uninstall packages or Lilyponds
  - [lyp update](#lyp-update) - update packages
  - [lyp use](#lyp-use) - switch between installed Lilyponds
  - [lyp version](#lyp-version) - show lyp version
  - [lyp watch](#lyp-watch) - watch files and directories and recompile on change
  - [lyp which](#lyp-which) - show location of packages or Lilyponds
- [Contributing](#contributing)

## Installation

### System requirements

Lyp is tested to work on Linux, macOS and Windows 7+.

### Installing lyp as a Ruby gem

_Note_: A recent version of Ruby (2.0.0 or later) is included in macOS 10.9.0 or later.

If you have a recent (>=1.9.3) version of Ruby on your machine, you can install lyp as a gem.

```bash
# Linux/macOS:
$ gem install lyp

# Windows:
> gem install lyp-win
```

### Installing lyp as a standalone release

If you don't have Ruby on your machine you can install lyp as a stand alone package using the install script ([view source](https://git.io/getlyp)):

```bash
$ curl -sSL https://git.io/getlyp | bash
```

or with Wget:

```bash
$ wget -qO- https://git.io/getlyp | bash
```

Windows users can simply download the latest Windows [release](https://github.com/noteflakes/lyp/releases), unzip it and run `lyp install self`:

```bash
> unzip lyp-0.2.3-win32.zip
> lyp-0.2.3-win32/bin/lyp install self
```

### Manually installing releases

(This section is for Linux / macOS users.)

If you feel uneasy about piping curl output to bash, you can install lyp yourself by downloading a [release](https://github.com/noteflakes/lyp/releases), untarring it, and running `lyp install self`:

```bash
$ cd /Downloads
# assuming linux-64 platform
$ tar -xzf lyp-0.2.1-linux-x86_64.tar.gz
$ lyp-0.2.1-linux-x86_64/lyp install self
```

**Note**: using the standalone release of lyp requires having git on your machine.

### Uninstalling lyp

In order to remove lyp from your system use the `uninstall self` command:

```bash
$ lyp uninstall self
```

This command will undo the changes made to your shell profile file, and remove any binaries from `~/.lyp/bin`.

In order to completely remove all files in `~/.lyp` you can simply delete the directory:

```bash
$ rm -rf ~/.lyp
```

## How lyp works

Lyp sets up a working directory in `~/.lyp` where it keeps its binaries,  installed packages, and installed versions of Lilypond. Lyp provides a wrapper script for Lilypond, which does the following:

- Select the correct version of Lilypond to use (see [below](#installing-and-using-lilypond)).
- Scan the given Lilypond file for any dependencies (specified using `\require`), and also recursively scan any include files for dependencies
- Resolve the dependency tree and calculate the correct versions to use for each required package.
- Create a wrapper Lilypond file that loads the packages.
- Invoke the selected version of Lilypond.

For more information on running Lilypond see the section on [Running Lilypond](#running-lilypond).

## Working with Packages

A package is a library of Lilypond code, containing one or more Lilypond files, that provide commonly-used functionality for users. A package can be a library of scheme code to extend Lilypond, as in [OpenLilyLib](https://github.com/openlilylib/); or a stylesheet which contains music fonts and additional Lilypond code to change the look of the music: font, spacing, line widths, sizes, etc.

The difference between merely copying and including a Lilypond file in your music, and using a Lilypond package is that you can easily share your music file with anyone and let them compile your music without having to download and copy additional code. lyp takes care of installing and resolving any dependencies in your Lilypond files, so that you can compile your Lilypond files anywhere without schlepping around a bunch of include files. Also, because packages are versioned, repeatable compilation using external code becomes trivial.

### What is a package?

In lyp, a package is a directory that should contain at least a single Lilypond file named `package.ly` in its root directory. A package could contain additional Lilypond and scheme files referenced in the main package file (using relative `\include`s). A package could also depend on other packages by using the `\require` command (see [below](#using-packages)).

Lyp packages are expected to be published as git repositories. The package is then versioned using git tags. A package can be referenced either using its git URL, a registered canonical name (if it's registered in the [lyp package index](https://github.com/lyp-packages/index)), or alternatively as a local path (which is really meant for package development more than anything else).

Packages can also include test files, examples that demonstrate proper usage, ruby source code for enhancing lyp itself, or alternative font files for creating a custom look for Lilypond scores.

### Installing packages

In order to install a package, use the `lyp install` command:

```bash
# install latest version of package dummy
$ lyp install dummy

# install version 0.2.0
$ lyp install github.com/ciconia/mypack@0.2.0

# install version 0.1.0 or higher
$ lyp install "mypack>=0.1.0"

# install from local path (see section below on developing packages)
$ lyp install mypack@dev:~/repo/mypack
```

To uninstall the package, use the `lyp uninstall` command:

```bash
# uninstall version 0.1.0
$ lyp uninstall dummy@0.1.0

# uninstall all versions of dummy
$ lyp uninstall -a dummy
```

To list currently installed packages use `lyp list` command:

```bash
# list all installed packages
$ lyp list

# list all installed packages matching the pattern 'font'
$ lyp list font
```

To list packages available on the lyp package index use the `lyp search` command:

```bash
# list all packages in index
lyp search

# list available packages matching pattern 'stylesheet'
lyp search stylesheet
```

### Automatic package installation

An easier way to install packages is by using the `lyp resolve` command, which installs all packages required for a given input file. Suppose a Lilypond called `test.ly` with the following content:

```lilypond
\version "2.19.35"
\require "assert"

#(assert-eq? 1 1)
#(assert:summary)
```

To install the `assert` package required in the file we run:

```bash
$ lyp resolve test.ly

Cloning https://github.com/lyp-packages/assert.git...

Installed assert@0.2.0
```

Package dependencies for a given input file can be shown using the `lyp deps` command:

```bash
$ lyp deps test.ly

  assert => 0.2.0
```

### Package references

A package is normally referenced by its git URL. Lyp lets you provide either fully- or partially qualified URLs. A package hosted on github can be also referenced by the user/repository pair. The following are all equivalent:

```bash
# Fully-qualified URLs
$ lyp install https://github.com/lyp-packages/package-template.git
$ lyp install https://github.com/lyp-packages/package-template

# Partially-qualified URL
$ lyp install github.com/lyp-packages/package-template

# Github repository id
$ lyp install noteflakes/lyp-package-template
```

In addition, lyp also provides an [index of publically available package](https://github.com/lyp-packages/index), which maps a package name to its URL (see also below). Using the index, packages are referenced by their published name instead of by their git URL:

```bash
$ lyp install dummy
```

To get a list of all available packages on the index, use the `lyp search` command.

### Version specifiers

When installing packages defining package dependencies, it is advisable to specify the desired version to use. Using definitive versions lets you ensure that your third-party dependencies do not change unexpectedly and do not break your code.

Versions can either be specified as specific version numbers, as version constraints or as descriptive names.

Versions are specified using the ampersand character:

```
package@0.1.0
package@stable
```

Version constraints specify a range of versions to use. Lyp currently supports two types of constraints:

- Optimistic constraint: `package>=0.1.0`, which means any version equal to or higher than 0.1.0.
- Pessimistic constraint: `package~>0.1.0`, which means any version equal or higher than 0.1.0, and lower than 0.2.0. This type of constraint is useful for packages which follow the semantic versioning standard.

Version specifiers could be used when installing, listing and requiring packages, and also for specifying versions of Lilypond (see [below](#installing-and-using-lilypond)). For example:

```bash
$ lyp install "dummy~>0.2.0"
```

**Note**: when using version constraints you should put the package specifier in quotes for bash properly parse the command.

### Using packages

To include a package in your Lilypond code, use the `\require` command:

```lilypond
\require "dummy"
\require "github.com/lulu/mypack>=0.4.0"
```

**Note**: once you use `\require` in your code, you will have to compile it using the Lilypond wrapper provided by lyp. It will not pass compilation using plain Lilypond.

Once the package requirements are defined, you can either install packages manually using [`lyp install`](#installing-packages), or automatically using [`lyp resolve`](#automatic-package-installation) as described above.

## Developing packages

To create a Lilypond package:

- Create a git repository.
- Add a `package.ly` file, which is the main entry point for your package.
- Optionally add additional Lilypond files or package dependencies.
- Test & debug your code (see [below](#testing-packages)).
- Publish your package (see [below](#publishing-packages)).

To test your package with an actual input file, you can install it from a local path (for more on testing see [below](#testing-packages)). Suppose your package is at ~/repo/mypack:

```bash
$ lyp install mypack@dev:~/repo/mypack
```

This will create a `mypack@dev` package referencing your local files, which you can then reference normally from an input file using the `\require` command:

```lilypond
\require "mypack@dev"
```

If the input file is residing inside your package (for example, [test files](#testing-packages)), you can require your package by specifying a relative path. Suppose the input file is at `mypack/test/mypack_test.ly`:

```lilypond
\require "mypack:.."
```

### The package interface

In order to facilitate writing complex packages, lyp defines a few variables and functions:

- `lyp:current-package-dir` - the absolute directory path for the current package (at the time the package is loaded)
- `lyp:input-filename` - the absolute path for the user's file being compiled
- `lyp:input-dirname` - the absolute directory path for the user's file being compiled

### Including files

Lyp provides the `\pinclude` and `\pincludeOnce` commands for including files residing in the current package using relative paths. The `\pincludeOnce` commands loads a given file only once:

```lilypond
\pincludeOnce "inc/init.ily"
\pinclude "inc/template.ily"
```

Lyp also defines a `lyp:load` scheme function for loading scheme files using relative paths without adding directories to the `%load-path`:

```lilypond
#(if (not (defined? 'mypack:init))(lyp:load "scm/init.scm"))
```

Loading scheme files that way is a better technique than adding directories to `%load-path`, because this way one avoids possible name clashes, which may lead to unexpected behavior.

### Conditional includes

Files can also be included conditionally by evaluating a scheme expression using the `\pcondInclude` and `\pcondIncludeOnce` commands:

```lilypond
% include edition-specific tweaks
\pcondInclude #(eq? edition 'urtext) "urtext_tweaks.ly"
```

### Scheme interface

Lyp provides to loaded packages a small API to facilitate handling relative paths and loading of Lilypond include files and scheme files. The API is documented on the [lyp wiki](https://github.com/noteflakes/lyp/wiki/Package-Scheme-Interface).  

### Including fonts

Lyp also supports automatic installation of fonts, based on work by [Abraham Lee](https://github.com/tisimst). When a package is installed, lyp will copy any font files residing in the `fonts` directory into the corresponding `otf` and `svg` directories of all installed versions of Lilypond.

**Note**: fonts will be only installed in versions of Lilypond starting from than 2.18.2. Lyp automatically patches any version newer than 2.19.12 in order to support custom fonts.

### Extending lyp

A package can also be used to extend or override lyp's stock functionality or add more features and commands. Extensions are written in Ruby in a file named `ext.rb` placed in the package's main directory. An extension can be used to either perform a certain action when the package is installed, or be loaded each time lyp is invoked.

When a package is installed, lyp executes the code in `ext.rb`. To make the extension run each time lyp is invoked, the extension should include the following line:

```ruby
Lyp.install_extension(__FILE__)
```

More commands can be added to lyp's command line interface by adding methods to the `Lyp::CLI` class using the [Thor](https://github.com/erikhuda/thor/wiki/Method-Options) API. For example:

```ruby
class Lyp::CLI
  desc "count", "show package count"
  def count
    packages = Lyp::Package.list_lyp_index("")
    puts "#{packages.size} packages installed"
  end
end
```

The implementation of the stock lyp commands can be be found in [`lib/lyp/cli.rb`](./lib/lyp/cli.rb).

### Testing Packages

Packages can be tested by using the `lyp test` command, which will compile any file found inside the package directory ending in `_test.ly`:

```bash
$ cd mypack
$ lyp test .
```

A test file can either be a simple Lilypond file which includes the package files and results in a Lilypond score, or a Lilypond file that performs unit tests on scheme code.

For more information on testing, see the [lyp-assert](https://github.com/lyp-packages/assert) package, which is meant to be used for unit testing Lilypond code, and serves as an example of how to test a package.

### Publishing packages

In order for your package to be available to all users, you'll need to first push your code to a publically accessible git repository (for example on github). Users will then be able to install your package by using the git URL of the public repository.

You can also add your package to the lyp [public package index](https://github.com/lyp-packages/index), by cloning it, editing [index.yaml](https://github.com/lyp-packages/index/blob/master/index.yaml), and creating a pull request.

## Installing and Using Lilypond

### Installing/uninstalling a version of Lilypond

When installing Lilypond, the specific version to download can be specified in different ways:

```bash
# latest stable version
$ lyp install lilypond

# latest stable version
$ lyp install lilypond@stable

# latest stable version
$ lyp install lilypond@unstable

# latest version
$ lyp install lilypond@latest

# version 2.18.1
$ lyp install lilypond@2.18.1

# highest version higher than 2.19.27
$ lyp install "lilypond>=2.19.27"

# highest 2.18 version higher than 2.18.1
$ lyp install "lilypond~>2.18.1"
```

To uninstall a version Lilypond use `lyp uninstall`

```bash
$ lyp uninstall lilypond@2.18.2
```

### Showing the list of installed Lilypond versions

To display all installed versions of Lilypond, use the `list` command:

```bash
$ lyp list lilypond
```

The output will look as follows:

```
Lilypond versions:

=> 2.18.2
   2.19.12
 * 2.19.35

# => - current
# =* - current && default
#  * - default
```

(For current, default settings see [below](#switching-between-lilypond-versions))

This will also list any versions of Lilypond found on the user's `$PATH` outside of the `~/.lyp` directory (these versions will be marked as 'system' versions).

### Showing available Lilypond versions

You can also list available versions of Lilypond by using the `search` command:

```bash
# display all available versions of Lilypond
$ lyp search lilypond

# display all available versions higher than 2.19
$ lyp search "lilypond>=2.19"

# display all available stable versions
$ lyp search "lilypond@stable"
````

The output will look as follows:

```
Available versions of lilypond@stable:

   2.8.8
   2.10.0
   2.10.33
   2.12.0
   2.12.3
   2.14.0
   2.14.2
   2.16.0
   2.16.1
   2.16.2
   2.18.0
   2.18.1
 * 2.18.2

 * Currently installed
```

### Switching between Lilypond versions

To switch between versions use the `lyp use`. The same version specifiers could be used as for the `lyp install` command:

```bash
$ lyp use lilypond@2.18.2 # the 'lilypond' identifier is optional

# use latest stable/unstable versions
$ lyp use stable
$ lyp use unstable
```

**Note**: The setting of the current Lilypond version to use will be maintained for the current shell session.

In order to switch the default version of Lilypond to use, add the `--default` switch:

```bash
$ lyp use --default 2.19.35
```

The version used can be further controlled using the `--use` and `--env` options passed to `lilypond` (see [below](#running-lilypond)).

As discussed [above](#showing-the-list-of-installed-lilypond-versions), the `lyp list lilypond` command displays the current and default settings. You can also display the path to the currently selected version by running `lyp which lilypond`:

```bash
$ lyp which lilypond
/Users/sharon/.lyp/lilyponds/2.18.2/bin/lilypond
```

### Running Lilypond

Once one or more versions of Lilypond are installed, the Lilypond command may be used normally to compile Lilypond files. Lyp adds a few extra options:

- `--auto-install-deps`, `-A` - automatically install any missing dependencies.

- `--cropped`, `-c` - produce a cropped score (requires setting margins to 0).

- `--env`, `-E` - use a version set by the `$LILYPOND_VERSION` environment variable:

  ```bash
  $ LILYPOND_VERSION=2.18.2 lilypond --env ...
  ```

- `--force-version`, `-F` - use the Lilypond version specified in the user file.

- `--install`, `-n` - install the specified version of Lilypond if not present. This option works only in conjunction with `--env` or `--use`:

  ```bash
  $ lilypond -u2.19.35 -n ...
  ```

- `--open`, `-O` - open target file after compilation.

- `--raw`, `-R` - do not pre-process input file (no scanning for dependencies, no wrapping).

  ```bash
  $ lilypond --raw ...
  ```

- `--require`, `--r` - require a package:

  ```bash
  $ lilypond -rassert mytest.ly
  ```

- `--snippet`, `-S` - produce a cropped PNG image at 600dpi

- `--use`, `-u` - use a specific version of Lilypond:

  ```bash
  $ lilypond --use=2.19.12 myfile.ly

  # version constraints can also be used:
  $ lilypond --use=">=2.19.12" myfile.ly
  $ lilypond --ustable myfile.ly
  $ lilypond --ulatest myfile.ly
  ```

## Command Reference

### lyp accelerate

Synopsis: `lyp accelerate`

Rewrites gem binaries for faster execution. When lyp is installed as a gem, the Rubygems system creates wrapper script files for `lyp` and `lilypond` which incur a performance penalty that adds up to 200msecs per invocation. Use this command to rewrite the gem binaries so as to improve their running time.

### lyp benchmark

Synopsis: `lyp benchmark FILE`

Benchmarks the running time of all installed versions of Lilypond using the given source file. This command accepts all Lilypond command line switches.

### lyp cleanup

Synopsis: `lyp cleanup`

Cleanup temporary files. lyp keeps a bunch of temporary directories and files under the system temporary directory, usually at `/tmp/lyp`. These include wrapper files, git repositories for installed packages, Lilypond archive files etc. These will normally be cleaned up by the OS after a period of time, but you can use this command to delete the entire content of this directory if you need the disk space.

### lyp compile

Synopsis: `lyp compile ... FILE`

Shorthand: `lyp c`

Compiles Lilypond source files. This command is synonymous to running `lilypond`. You can pass along any switches accepted by Lilypond. In addition, lyp adds a few options to provide additional functionality:

- `--auto-install-deps`/`-a`: install any missing dependencies
- `--cropped`/`-c`: crop output (requires setting 0 margins)
- `--env`/`-E`: use the Lilypond version specified in the `LILYPOND_VERSION` environment variable:

  ```bash
  $ LILYPOND_VERSION=2.19.50 lyp c mysuperscore.ly
  ```

- `--force-version`/`-F`: use Lilypond version specified in user file
- `--install`/`-n`: install version of Lilypond if not found (if the required version was overriden using any of `--env`, `--force-version` or `--use`)
- `--open`/`-O`: open output file after compilation
- `--raw`/`-R`: run Lilypond "raw" (no pre-processing of dependencies)
- `--require=PACKAGE`/`-rPACKAGE`: preload the specified package

  ```bash
  $ lyp -rassert mytests.ly
  ```

- `--snippet`/`-S`: produce png cropped images at 600dpi (equivalent to `--cropped --png -dresolution=600`)
- `--use=VERSION`/`-uVERSION`: use the given version of Lilypond:
  
  ```bash
  $ lyp c -u2.19.53 myfile.ly
  # automatically install given version of Lilypond
  $ lyp c -nu2.19.53 myfile.ly
  ```

### lyp deps

Synopsis: `lyp deps FILE`

Shows dependencies for a given source file.

### lyp exec

Synopsis: `lyp exec SCRIPT ...`

Shorthand: `lyp x`

Runs a Lilypond script (using the currently selected version of Lilypond).

### lyp flatten

Synopsis: `lyp flatten FILE`

Flattens a source file and all included files into a single file.

### lyp install

Synopsis: `lyp install PACKAGE|lilypond@VERSION`

Shorthand: `lyp i`

Installs a package or a Lilypond. See [installing packages](#installing-packages) and [installing versions of Lilypond](#installing-and-using-lilypond) above.

### lyp list

Synopsis: `lyp list [PACKAGE|lilypond]`

Shorthand: `lyp l`

Lists installed packages or Lilyponds.

### lyp resolve

Synopsis: `lyp resolve FILE``

Resolves and optionally installs all dependencies for a given source file. To install required dependencies use the `--all`/`-a` switch:

```bash
$ lyp resolve -a myfile.ly
```

### lyp search

Synopsis: `lyp search PACKAGE|lilypond``

Shorthand: `lyp s`

Searches for packages or versions of Lilypond.

### lyp test

Synopsis: `lyp test DIRECTORY`

Shorthand: `lyp t`

Runs Lilypond tests by compiling all files in the given directory matching the pattern `*-test.ly`.

### lyp uninstall

Synopsis: `lyp uninstall PACKAGE|lilypond@VERSION`

Shorthand: `lyp u`

Uninstalls a package or a Lilypond.

### lyp update

Synopsis: `lyp update PACKAGE`

Updates an installed package to its latest available version.

### lyp use

Synopsis: `lyp use VERSION``

Shorthand: `lyp U`

Switches to a different version of Lilypond. To set the default version, use the `--default` switch:

```bash
$ lyp use --default 2.19.52
```

### lyp version

Synopsis: `lyp version``

Shorthand: `lyp -v``

Displays the version of lyp.

### lyp watch

Synopsis: `lyp watch DIRECTORY|FILE...``

Shorthand: `lyp w`

Watches one or more directories or files and recompiles any files that have been modified. To watch a directory of include files and always recompile the same project file, use the `--target`/`-t` switch:

```bash
$ lyp watch bwv35 --target bwv35/score.ly
```

This command accepts all Lilypond command line switches.

### lyp which

Synopsis: `lyp which PACKAGE|lilypond`

Shows the location of the given package or the currently selected Lilypond.

## Contributing

Lyp is written in Ruby, and its code is [available on github](https://github.com/noteflakes/lyp). To hack on it, simply clone the repository. To run the specs:

```bash
$ cd lyp
$ bundle install # needs to be run only once
$ rspec
```

Please feel free to submit issues and pull requests.
