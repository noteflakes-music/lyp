[![Build Status](https://travis-ci.org/noteflakes/lyp.svg?branch=master)](https://travis-ci.org/noteflakes/lyp)

# lyp - a package manager for lilypond

Use lyp to install and manage packages for lilypond, and install and manage multiple versions of lilypond on your machine.

__Code reuse__: lyp lets you install packages that act as lilypond code libraries and can be used to enhance your lilypond files with additional functionality. Packages can depend on other packages. Lyp resolves both direct and transitive package dependencies, and automatically selects the correct version to use for each package.

__No hassle Lilypond installation__: With lyp you can also install any version of lilypond on your machine with a single command, without having to visit the lilypond website, clicking a link and then copying files around. In addition, lyp lets you switch between multiple versions of lilypond and always keep your machine up to date with the latest version.

## Table of contents

- [Installation](#installation)
  - [How lyp works](#how-lyp-works)
  - [Uninstalling](#uninstalling)
- [Working with packages](#working-with-packages)
  - [What constitutes a package?](#what-constitutes-a-package)
  - [Installing packages](#installing-packages)
  - [Automatic package installation](#automatic-package-installation)
  - [Package references](#package-references)
  - [Version specifiers](#version-specifiers)
  - [Using packages](#using-packages)
- [Developing packages](#developing-packages)
  - [The package interface](#the-package-interface)
  - [Including files](#including-files)
  - [Including fonts](#including-fonts)
  - [Testing packages](#testing-packages)
  - [Publishing packages](#publishing-packages)
- [Installing and Using Lilypond](#installing-and-using-lilypond)
  - [Installing/uninstalling a version of lilypond](#installing-uninstalling a version of lilypond)
  - [Showing the list of installed lilypond versions](#showing-the-list-of-installed-lilypond-versions)
  - [Showing available lilypond versions](#Showing-available-lilypond-versions)
  - [Switching between lilypond versions](#switching-between-lilypond-versions)
  - [Running lilypond](#running-lilypond)
- [Contributing](#contributing)

## Installation

**Note**: lyp is tested to work on Linux and Mac OSX. Installing and using it on Windows would probably be problematic.

#### Installing lyp as a Ruby gem

If you have a recent (>=1.9.3) version of Ruby on your machine, you can install lyp as a gem:

```bash
$ gem install lyp
$ lyp install self
```

The `lyp install self` command is needed in order to setup the `~/.lyp` working directory and add the lyp binaries directory to your `PATH` (see below), by adding a line of code to your shell profile file.

#### Installing lyp without Ruby

If you don't have Ruby on your machine you can install lyp as a stand alone package using the install script ([view source](https://git.io/getlyp)):

```bash
$ curl -sSL https://git.io/getlyp | bash
```

or with Wget:

```bash
$ wget -qO- https://git.io/getlyp | bash
```

If you feel uneasy about piping curl output to bash, you can install lyp yourself by downloading a [release](https://github.com/noteflakes/lyp/releases), untarring it, and running `lyp install self`:

```bash
$ cd /Downloads
# assuming linux-64 platform
$ tar -xzf lyp-0.2.1-linux-x86_64.tar.gz
$ lyp-0.2.1-linux-x86_64/lyp install self
```

https://github.com/noteflakes/lyp/releases/download/v0.2.1/lyp-0.2.1-linux-x86_64.tar.gz

**Note**: using the standalone release of lyp requires having git on your machine.

### How lyp works

Lyp sets up a working directory in `~/.lyp` where it keeps its binaries,  installed packages, and installed versions of lilypond. Lyp provides a wrapper script for lilypond, which does the following:

- Select the correct version of lilypond to use (see below).
- Scan the given lilypond file for any dependencies (specified using `\require`), and also recursively scan any include files for dependencies
- Resolve the dependency tree and calculate the correct versions to use for each required package.
- Create a wrapper lilypond file that loads the packages.
- Invoke the selected version of lilypond.

For more information on running lilypond see the section on [Running lilypond](#running-lilypond).

### Uninstalling

In order to remove lyp from your system use the `uninstall self` command:

```bash
$ lyp uninstall self
```

This command will undo the changes made to your shell profile file, and remove any binaries from `~/.lyp/bin`.

In order to completely remove all files in `~/.lyp` you can simply delete the directory:

```bash
$ rm -rf ~/.lyp
```

## Working with Packages

A package is a library of lilypond code, containing one or more lilypond files, that provide commonly-used functionality for users. A package can be a library of scheme code to extend lilypond, as in openlilylib; or a stylesheet which contains music fonts and additional lilypond code to change the look of the music: font, spacing, line widths, sizes, etc.

The difference between merely copying and including a lilypond file in your music, and using a lilypond package is that you can easily share your music file with anyone and let them compile your music without having to download and copy additional code. lyp takes care of installing and resolving any dependencies in your lilypond files, so that you can compile your lilypond files anywhere without schlepping around a bunch of include files. Also, because packages are versioned, repeatable compilation using external code becomes trivial. 

### What constitutes a package?

In lyp, a package should contain at least a single lilypond file named `package.ly` in its root directory. A package could contain additional lilypond files referenced in the main package file (using relative includes). A package could also depend on other packages by using the `\require` command (see below).

Lilypond packages are expected to be published as git repositories. The packages is then versioned using git tags. A package can be referenced either using its git URL, a short name (if it's registered in the [lyp package index](https://github.com/noteflakes/lyp-index)), or alternatively as a local path (which is meant for package development more than anything else).

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

An easier way to install packages is by using the `lyp resolve` command, which installs all packages required for a given input file. Suppose a lilypond called `test.ly` with the following content:

```lilypond
\version "2.19.35"
\require "assert"

#(assert-eq? 1 1)
#(assert:summary)
```

To install the `assert` package required in the file we run:

```bash
$ lyp resolve test.ly
#=>
Cloning https://github.com/noteflakes/lyp-assert.git...

Installed assert@0.2.0
```

Package dependencies for a given input file can be shown using the `lyp deps` command:

```bash
$ lyp deps test.ly
#=>
  assert => 0.2.0
```

### Package references

A package is normally referenced by its git URL. Lyp lets you provide either fully- or partially qualified URLs. A package hosted on github can be also referenced by the user/repository pair. The following are all equivalent:

```bash
# Fully-qualified URLs
$ lyp install https://github.com/noteflakes/lyp-package-template.git
$ lyp install https://github.com/noteflakes/lyp-package-template

# Partially-qualified URL
$ lyp install github.com/noteflakes/lyp-package-template

# Github repository id
$ lyp install noteflakes/lyp-package-template
```

In addition, lyp also provides an [index of publically available package](https://github.com/noteflakes/lyp-index), which maps a package name to its URL (see also below). Using the index, packages are referenced by their published name instead of by their git URL:

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

Version specifiers could be used when installing, listing and requiring packages, and also for specifying versions of lilypond (see below). For example:

```bash
$ lyp install "dummy~>0.2.0"
```

**Note**: when using version constraints you should put the package specifier in quotes for bash properly parse the command.

### Requiring packages

To include a package in your lilypond code, use the `\require` command:

```lilypond
\require "dummy"
\require "github.com/lulu/mypack>=0.4.0"
```

**Note**: once you use `\require` in your code, you will have to compile it using the lilypond wrapper provided by lyp. It will not pass compilation using plain lilypond.

Once the package requirements are defined, you can either install packages manually using [`lyp install`](#installing-packages), or automatically using [`lyp resolve`](#automatic-package-installation) as described above.

## Developing packages

To create a lilypond package:

- Create a git repository.
- Add a `package.ly` file, which is the main entry point for your package.
- Optionally add additional lilypond files or package dependencies.
- Test & debug your code (see below).
- Publish your package (see below).

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

Loading scheme files that way is a better technique than adding directorys to `%load-path`, because this way one avoids possible name clashes, which may lead to unexpected behavior.

### Including fonts

Lyp also supports automatic installation of fonts, based on work by [Abraham Leigh](https://github.com/tisimst). When a package is installed, lyp will copy any font files residing in the `fonts` directory into the corresponding `otf` and `svg` directories of all installed versions of lilypond.

**Note**: fonts will be only installed in versions of lilypond starting from than 2.18.2. Lyp automatically patches any version ower than 2.19.12 in order to support custom fonts. 

### Testing Packages

Packages can be tested by using the `lyp test` command, which will compile any file found inside the package directory ending in `_test.ly`:

```bash
$ cd mypack
$ lyp test .
```

A test file can either be a simple lilypond file which includes the package files and results in a lilypond score, or a lilypond file that performs unit tests on scheme code.

For more information on testing, see the [lyp-assert](https://github.com/noteflakes/lyp-assert) package, which is meant to be used for unit testing lilypond code, and serves as an example of how to test a package.

### Publishing packages

In order for your package to be available to all users, you'll need to first push your code to a publically accessible git repository (for example on github). Users will then be able to install your package by using the git URL of the public repository.

You can also add your package to the lyp [public package index](https://github.com/noteflakes/lyp-index), by cloning it, editing [index.yaml](https://github.com/noteflakes/lyp-index/blob/master/index.yaml), and creating a pull request.

## Installing and Using Lilypond

### Installing/uninstalling a version of lilypond

When installing lilypond, the specific version to download can be specified in different ways:

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

To uninstall a version lilypond use `lyp uninstall`

```bash
$ lyp uninstall lilypond@2.18.2
```

### Showing the list of installed lilypond versions

To display all installed versions of lilypond, use the `list` command:
  
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

(For current, default settings see below)

This will also list any versions of lilypond found on the user's `$PATH` outside of the `~/.lyp` directory (these versions will be marked as 'system' versions).

### Showing available lilypond versions

You can also list available versions of lilypond by using the `search` command:

```bash
# display all available versions of lilypond
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

### Switching between lilypond versions

To switch between versions use the `lyp use`. The same version specifiers could be used as for the `lyp install` command:

```bash
$ lyp use lilypond@2.18.2 # the 'lilypond' identifier is optional

# use latest stable/unstable versions
$ lyp use stable
$ lyp use unstable
```

**Note**: The setting of the current lilypond version to use will be maintained for the current shell session.

In order to switch the default version of lilypond to use, add the `--default` switch:

```bash
$ lyp use --default 2.19.35
```

The version used can be further controlled using the `--use` and `--env` options passed to `lilypond` (see below).

As discussed [above](#showing-the-list-of-installed-lilypond-versions), the `lyp list lilypond` command displays the current and default settings. You can also display the path to the currently selected version by running `lyp which lilypond`:

```bash
$ lyp which lilypond
#=> /Users/sharon/.lyp/lilyponds/2.18.2/bin/lilypond
```

### Running lilypond

Once one or more versions of lilypond are installed, the lilypond command may be used normally to compile lilypond files. Lyp adds a few extra options:

- `--use`, `-u` - use a specific version of lilypond:

  ```bash
  $ lilypond --use=2.19.12 ...

  # version constraints can also be used:
  $ lilypond --use=">=2.19.12" ...
  $ lilypond --use=stable ...
  $ lilypond --use=latest ...
  ```
  
- `--env`, `-E` - use a version set by the `$LILYPOND_VERSION` environment variable:

  ```bash
  $ LILYPOND_VERSION=2.18.2 lilypond --env ...
  ```

- `--install`, `-n` - install the specified version of lilypond if not present. This option works only in conjunction with `--env` or `--use`:

  ```bash
  $ lilypond -u2.19.35 -n ...
  ```
  
- `--raw`, `-r` - do not pre-process input file (no scanning for dependencies, no wrapping).

  ```bash
  $ lilypond --raw ...
  ```

## Contributing

Lyp is written in Ruby, and its code is [available on github](https://github.com/noteflakes/lyp). To hack on it, simply clone the repository. To run the specs:

```bash
$ cd lyp
$ bundle install # needs to be run only once
$ rspec
```

Please feel free to submit issues and pull requests.