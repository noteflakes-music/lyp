[![Build Status](https://travis-ci.org/noteflakes/lyp.svg?branch=master)](https://travis-ci.org/noteflakes/lyp)

# lyp - a package manager for lilypond

Use lyp to install and manage packages for lilypond, and install and manage multiple versions of lilypond on your machine.

__Code reuse__: lyp lets you install packages that act as lilypond code libraries and can be used to enhance your lilypond files with additional functionality. Packages can depend on other packages. Lyp resolves both direct and transitive package dependencies, and automatically selects the correct version to use for each package.

__No hassle Lilypond installation__: With lyp you can also install any version of lilypond on your machine with a single command, without having to visit the lilypond website, clicking a link and then copying files around. In addition, lyp lets you switch between multiple versions of lilypond and always keep your machine up to date with the latest version.

## Table of contents

- [Installation](#installation)
  - [How lyp works](#how-lyp-works)
  - [Uninstalling](#uninstalling)
- [Lilypond packages](#lilypond-packages)
  - [What constitutes a package?](#what-constitutes-a-package)
  - [Installing packages](#installing-packages)
  - [Package references](#package-references)
  - [Version specifiers](#version-specifiers)
  - [Using packages](#using-packages)
  - [Developing packages](#developing-packages)
- [Installing and switching Lilypond versions](#installing-and-switching-lilypond-versions)
- [Contributing](#contributing)

## Installation

**Note**: lyp is tested to work on Linux and Mac OSX. Installing and using it on Windows would probably be problematic.

#### Installing lyp as a Ruby gem

If you have a recent (>=1.9.3) version of Ruby on your machine, you can install lyp as a gem:

```bash
gem install lyp
lyp install self
```

The `lyp install self` command is needed in order to setup the `~/.lyp` working directory and add the lyp binaries directory to your `PATH` (see below), by adding a line of code to your shell profile file.

#### Installing lyp without Ruby

If you don't have Ruby on your machine you can install lyp as a stand alone package using the [install script](https://raw.githubusercontent.com/noteflakes/lyp/master/bin/install_release.sh):

```bash
curl -sSL https://git.io/getlyp | bash
```

or with Wget:

```bash
wget -qO- https://git.io/getlyp | bash
```

**Note**: installing the standalone release of lyp requires a having git installed.

#### Uninstalling lyp

To uninstall lyp:

```bash
lyp uninstall self
```

This will remove `~/.lyp/bin` from your `PATH` and remove the lyp binary scripts.

### How lyp works

Lyp sets up a working directory in `~/.lyp` where it keeps its binaries,  installed packages, and installed versions of lilypond. Lyp provides a wrapper script for lilypond, which does the following:

- Select the correct version of lilypond to use (see below).
- Scan the given lilypond file for any dependencies (specified using `\require`), and also recursively scan any include files for dependencies
- Resolve the dependency tree and calculate the correct versions to use for each required package.
- Create a wrapper lilypond file that loads the packages.
- Invoke the selected version of lilypond.

### Uninstalling

In order to remove lyp from your system use the `uninstall self` command:

```bash
lyp uninstall self
```

This command will undo the changes made to your shell profile file, and remove any binaries from `~/.lyp/bin`.

In order to completely remove all files in `~/.lyp` you can simply delete the directory:

```bash
rm -rf ~/.lyp
```

## Lilypond packages

A package is a library of lilypond code, containing one or more lilypond files, that provide commonly-used functionality for users. A package can be a library of scheme code to extend lilypond, as in openlilylib; or a stylesheet which contains music fonts and additional lilypond code to change the look of the music: font, spacing, line widths, sizes, etc.

The difference between merely copying and including a lilypond file in your music, and using a lilypond package is that you can easily share your music file with anyone and let them compile your music without having to download and copy additional code. lyp takes care of installing and resolving any dependencies in your lilypond files, so that you can compile your lilypond files anywhere without schlepping around a bunch of include files. Also, because packages are versioned, repeatable compilation using external code becomes trivial. 

### What constitutes a package?

In lyp, a package should contain at least a single lilypond file named `package.ly` in its root directory. A package could contain additional lilypond files referenced in the main package file (using relative includes). A package could also depend on other packages by using the `\require` command (see below).

Lilypond packages are expected to be published as git repositories. The packages is then versioned using git tags. A package can be referenced either using its git URL, a short name (if it's registered in the [lyp package index](https://github.com/noteflakes/lyp-index)), or alternatively as a local path (which is meant for package development more than anything else).

### Installing packages

In order to install a package, use the `lyp install` command:

```bash
lyp install dummy # install latest version of package dummy
lyp install github.com/ciconia/mypack@0.2.0 # install version 0.2.0
lyp install mypack>=0.1.0 # install version 0.1.0 or higher
lyp install mypack@dev:~/repo/mypack # install from local opath
```

To uninstall the package, use the `lyp uninstall` command:

```bash
lyp uninstall dummy@0.1.0 # uninstall version 0.1.0
lyp uninstall -a dummy # uninstall all versions of dummy
```

To list currently installed packages use `lyp list` command:

```bash
lyp list # list all installed packages
lyp list font # list all installed packages matching the pattern 'font'
```

To list packages available on the lyp package index use the `lyp search` command:

```bash
lyp search # list all packages in index
lyp search stylesheet # list available packages matching pattern 'stylesheet'
```

### Package references

A package is normally referenced by its git URL. Lyp lets you provide either fully- or partially qualified URLs. A package hosted on github can be also referenced by the user/repository pair. The following are all equivalent:

```bash
lyp install https://github.com/noteflakes/lyp-package-template.git
lyp install https://github.com/noteflakes/lyp-package-template
lyp install github.com/noteflakes/lyp-package-template
lyp install noteflakes/lyp-package-template
```

In addition, lyp also provides an [index of publically available package](https://github.com/noteflakes/lyp-index), which maps a package name to its URL (see also below). Using the index, packages are referenced by their published name instead of by their git URL:

```bash
lyp install dummy
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
lyp install "dummy~>0.2.0"
```

(__Note__: that when using version constraints you should put the package specifier in quotes)

### Using packages

To include a package in your lilypond code, use ther `\require` command:

```lilypond
\require "dummy"
\require "github.com/lulu/mypack>=0.4.0"
```

It is important to note that once you use `\require` in your code, you will have to compile it using the lilypond wrapper provided by lyp. It will not pass compilation using plain lilypond.

### Developing packages

To create a lilypond package:

- Create a git repository.
- Add a `package.ly` file, which is the main entry point for your package.
- Optionally add additional lilypond files or package dependencies.
- Test & debug your code (see below).
- Publish your package (see below).

To test your package code, you can install it from a local path. Suppose your package is at ~/repo/mypack:

```bash
lyp install mypack@dev:~/repo/mypack
```

This will create a `mypack@dev` package referencing your local files, which you can then reference from a test file in your package using the `\require` command:

```lilypond
\require "mypack@dev"
```

### Publishing packages

In order for your package to be available to all users, you'll need to first push your code to a publically accessible git repository (for example on github). Users will then be able to install your package by using the git URL of the public repository.

You can also add your package to the lyp [public package index](https://github.com/noteflakes/lyp-index), by cloning it, editing [index.yaml](https://github.com/noteflakes/lyp-index/blob/master/index.yaml), and creating a pull request.

## Installing and switching Lilypond versions

When installing lilypond, the specific version to download can be specified in different ways:

```bash
lyp install lilypond % latest stable version
lyp install lilypond@stable % latest stable version
lyp install lilypond@unstable % latest stable version
lyp install lilypond@latest % latest version
lyp install lilypond@2.18.1 % version 2.18.1
lyp install "lilypond>=2.19.27" % highest version higher than 2.19.27
lyp install "lilypond~>2.18.1" % highest 2.18 version higher than 2.18.1
```

To display all installed versions of lilypond, use the `list` command:
  
```bash
lyp list lilypond
```

This will also list any versions of lilypond found outside of the `~/.lyp` directory.

You can also list available versions of lilypond by using the `search` command:

```bash
lyp search lilypond # display all available versions of lilypond
lyp search "lilypond>=2.19" # display all available versions higher than 2.19
lyp search "lilypond@stable" # display all available stable versions
````

To switch between versions use the `lyp use`. The same version specifiers could be used as for the `lyp install` command:

```bash
lyp use lilypond@2.18.2 % or without the 'lilypond' identifier:
lyp use stable % use latest stable version 
lyp use unstable % use latest unstable version 
```

The setting of the current lilypond version to use will be maintained for the current shell session.

In order to switch the default version of lilypond to use, add the `--default` switch:

```bash
lyp use --default 2.19.35
```

## Contributing

Lyp is written in Ruby, and its code is [available on github](https://github.com/noteflakes/lyp). To hack on it, siply clone the repository. To run the specs:

```bash
rspec
```

Please feel free to submit issues and pull requests.