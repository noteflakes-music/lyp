# lyp - The Lilypond Swiss Army Knife

lyp is an open-source tool that takes the pain out of working with [Lilypond](http://lilypond.org/).

__Use packages__: Install <a href="#" jump-to-id="working-with-packages">packages</a> to enhance your Lilypond files with additional functionality. Add <a href="#" router-link="/packages?id=tweaking">specialized tweaks</a> or even <a href="/#" router-link="/packages?id=fonts">change the music font</a>.

__No hassle Lilypond installation__: with lyp you can <a href="#" jump-to-id="installing-and-using-lilypond">install Lilypond</a> with a single easy command, no need to click links, or unzip and copy files around.

__Even more tools for power users__: watch and automatically <a href="#" jump-to-id="lyp-watch">recompile</a> changed source files, <a href="#" jump-to-id="lyp-flatten">flatten</a> include files, and <a href="#" jump-to-id="lyp-compile">automatically install</a> package dependencies or any required version of Lilypond.

## Installation

### System requirements

lyp is tested to work on recent versions of Linux, macOS and Windows.

### Installing lyp as a Ruby gem

If you have a recent (>=1.9.3) version of Ruby on your machine, you can install lyp as a gem.

_Note_: A recent version of Ruby (2.0.0 or later) is included in macOS 10.9.0 or later.

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
$ tar -xzf lyp-1.3.2-linux-x86_64.tar.gz
$ lyp-1.3.2-linux-x86_64/lyp install self
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

lyp sets up a working directory in `~/.lyp` where it keeps its binaries,  installed packages, and installed versions of Lilypond. lyp provides a wrapper script for Lilypond, which does the following:

- Select the correct version of Lilypond to use (see <a href="#" jump-to-id="installing-and-using-lilypond">below</a>).
- Scan the given Lilypond file for any dependencies (specified using `\require`), and also recursively scan any include files for dependencies
- Resolve the dependency tree and calculate the correct versions to use for each required package.
- Create a wrapper Lilypond file that loads the packages.
- Invoke the selected version of Lilypond.

For more information on running Lilypond see the section on <a href="#" jump-to-id="running-lilypond">Running Lilypond</a>.

## Working with Packages

A package is a library of Lilypond code, containing one or more Lilypond files, that provide commonly-used functionality for users. A package can be a library of scheme code to extend Lilypond, as in [OpenLilyLib](https://github.com/openlilylib/); or a stylesheet which contains music fonts and additional Lilypond code to change the look of the music: font, spacing, line widths, sizes, etc.

The difference between merely copying and including a Lilypond file in your music, and using a Lilypond package is that you can easily share your music file with anyone and let them compile your music without having to download and copy additional code. lyp takes care of installing and resolving any dependencies in your Lilypond files, so that you can compile your Lilypond files anywhere without schlepping around a bunch of include files. Also, because packages are versioned, repeatable compilation using external code becomes trivial.

### What is a package?

In lyp, a package is a directory that should contain at least a single Lilypond file named `package.ly` in its root directory. A package could contain additional Lilypond and scheme files referenced in the main package file (using relative `\include`s). A package could also depend on other packages by using the `\require` command (see <a href="#" jump-to-id="using-packages">below</a>).

lyp packages are expected to be published as git repositories. The package is then versioned using git tags. A package can be referenced either using its git URL, a registered canonical name (if it's registered in the [lyp package index](https://github.com/lyp-packages/index)), or alternatively as a local path (which is really meant for package development more than anything else).

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

A package is normally referenced by its git URL. lyp lets you provide either fully- or partially qualified URLs. A package hosted on github can be also referenced by the user/repository pair. The following are all equivalent:

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

Version constraints specify a range of versions to use. lyp currently supports two types of constraints:

- Optimistic constraint: `package>=0.1.0`, which means any version equal to or higher than 0.1.0.
- Pessimistic constraint: `package~>0.1.0`, which means any version equal or higher than 0.1.0, and lower than 0.2.0. This type of constraint is useful for packages which follow the semantic versioning standard.

Version specifiers could be used when installing, listing and requiring packages, and also for specifying versions of Lilypond (see <a href="#" jump-to-id="installing-and-using-lilypond">below</a>). For example:

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

Once the package requirements are defined, you can either install packages manually using <a href="#" jump-to-id="installing-packages">`lyp install`</a>, or automatically using <a href="#" jump-to-id="automatic-package-installation">`lyp resolve`</a> as described above.

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

(For current, default settings see <a href="#" jump-to-id="switching-between-lilypond-versions">below</a>)

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

The version used can be further controlled using the `--use` and `--env` options passed to `lilypond` (see <a href="#" jump-to-id="running-lilypond">below</a>).

As discussed <a href="#" jump-to-id="showing-the-list-of-installed-lilypond-versions">above</a>, the `lyp list lilypond` command displays the current and default settings. You can also display the path to the currently selected version by running `lyp which lilypond`:

```bash
$ lyp which lilypond
/Users/sharon/.lyp/lilyponds/2.18.2/bin/lilypond
```

### Running Lilypond

Once one or more versions of Lilypond are installed, the Lilypond command may be used normally to compile Lilypond files. lyp adds a few extra options:

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

Synopsis: `lyp flatten SOURCE [DEST]`

Flattens the given input file at `SOURCE` and all included files into a single file to be written to `DEST`. If `DEST` is not specified, the file is written to `STDOUT`.

### lyp install

Synopsis: `lyp install PACKAGE|lilypond@VERSION`

Shorthand: `lyp i`

Installs a package or a Lilypond. See <a href="#" jump-to-id="installing-packages">installing packages</a> and <a href="#" jump-to-id="installing-and-using-lilypond">installing versions of Lilypond</a> above.

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

