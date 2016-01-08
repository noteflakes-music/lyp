[![Build Status](https://travis-ci.org/ciconia/lyp.svg?branch=master)](https://travis-ci.org/ciconia/lyp)

# lyp - a package manager for lilypond

lyp is a tool to install and manage packages for lilypond, and install versions of lilypond.

lyp lets you install lilypond packages that act as code libraries and can be used to enhance your lilypond files with additional functionality. Packages can depend on other packages. Lyp resolves the direct and transitive package dependencies, and selects the correct version to use for each package.

With lyp you can also install any version of lilypond on your machine with a single command, without having to visit the lilypond website, clicking a link and then copying files around. In addition, lyp lets you install multiple versions of lilypond and easily switch between them.

## What is a lilypond package?

A package is a library of lilypond code, containing one or more lilypond files, that provide commonly-used functionality for users. A package can be a library of scheme code to extend lilypond, as in openlilylib; or a stylesheet which contains music fonts and additional lilypond code to change the look of the music: font, spacing, line widths, sizes, etc.

The difference between merely copying and including a lilypond file in your music, and using a lilypond package is that you can easily share your music file with anyone and let them compile your music without having to download and copy additional code. lyp takes care of installing and resolving any dependencies in your lilypond files, so that you can compile your lilypond files anywhere without schlepping around a bunch of include files. Also, because packages are versioned, repeatable compilation using external code becomes trivial. 

## How to add a package to your lilypond file?

Lilypond packages are simply git repositories. As such they can be identified by the repository's URL, or by the github repository path. To add a package dependency to your code, use the <code>\require</code> command:

```lilypond
\require "lypco/lilyjazz" % repository is at: github.com/lypco/lilyjazz
\require "github.com/lypco/poormans_henle"
```

Versions can be specified either as specific versions, or as version specifiers which denote a range of versions:

```lilypond
\require "lypco/lilyjazz@0.3.2"

% highest version higher than 0.3.2
\require "lypco/lilyjazz@>=0.3.2"

% highest version higher than 0.4.5 but lower than 0.5.0
\require "lypco/lilyjazz@~>0.4.5"
```

Once the dependencies are specified, packages can be installed either using the <install> command:
  
```bash
lyp install "lypco/lilyjazz@0.3.2" % OR:
lyp install "lypco/lilyjazz@>=0.3.2"
```

... or the <code>resolve</code> command, which scans the user's file for dependencies and then installs them:

```bash
lyp resolve maitre_sans_marteau.ly
```

## Installation

If you have Ruby on your machine, you can simply install the lyp gem, and run the install self command:

```bash
gem install lyp
lyp install self
```

## Installing packages with lyp



## Installing and managing versions of lilypond

When installing lilypond, the specific version to download can be specified in different ways:

```bash
lyp install lilypond % latest stable version
lyp install lilypond@stable % latest stable version
lyp install lilypond@unstable % latest stable version
lyp install lilypond@latest % latest version
lyp install lilypond@2.18.1 % version 2.18.1
lyp install lilypond@>=2.19.27 % highest version higher than 2.19.27
lyp install lilypond@~>2.18.1 % highest 2.18 version higher than 2.18.1
```

To display all installed versions of lilypond, use the <code>list</code> command:
  
```bash
lyp list lilypond
```

To switch between versions use the <code>use</code>. The same version specifiers could be used as for the <code>install</code> command:

```bash
lyp use lilypond@2.18.2 % or without the 'lilypond' identifier:
lyp use stable % use latest stable version 
```

To show all versions available for download, use the <code>search</code> command:
  
```bash
lyp search lilypond
```