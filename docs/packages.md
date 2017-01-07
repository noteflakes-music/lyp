---
title: Package Directory
---

# The semi-offical [lyp](https://github.com/noteflakes/lyp#readme) package index

## Editorial tools

* [edition-engraver](https://github.com/lyp-packages/edition-engraver) - Editorial tweaking for Lilypond.

## Fonts

* [beethoven](https://github.com/lyp-packages/beethoven) - Beethoven font package.
* [bravura](https://github.com/lyp-packages/bravura) - Bravura SMuFL font for Lilypond.
* [gootville](https://github.com/lyp-packages/gootville) - Gootville SMuFL font for Lilypond (based on Gonville).
* [haydn](https://github.com/lyp-packages/haydn) - Haydn font package.
* [lilyjazz](https://github.com/lyp-packages/lilyjazz) - LilyJazz font package.
* [paganini](https://github.com/lyp-packages/paganini) - Paganini font package.
* [profondo](https://github.com/lyp-packages/profondo) - Profondo font package (a non-SMuFL Bravura clone).
* [smufl](https://github.com/lyp-packages/smufl) - Support for SMuFL fonts.

## Frameworks

* [structure](https://github.com/noteflakes/lyp-structure) - A framework for writing big scores in Lilypond (WIP).

## Harmony

* [microlily](https://github.com/lyp-packages/microlily) - Microtonal support for Lilypond.
* [roman-numerals](https://github.com/lyp-packages/roman-numerals) - A package for roman numeral harmonic analysis.

## Instrument-specific notation

* [lilydrum](https://github.com/lyp-packages/lilydrum) - Right-left drum notation (mainly for pipeband snare drumming).

## OpenLilyLib

* [oll-core](https://github.com/lyp-packages/oll-core) - Basic functionality for OpenLilyLib packages.
* [oll-ji](https://github.com/lyp-packages/oll-ji) - Commands for notating music in just notation.

## Special notation

* [slashed-beams](https://github.com/lyp-packages/slashed-beams) - Slashed beams for Lilypond.
* [pedal-decorations](https://github.com/lyp-packages/pedal-decorations) - Pedal mark decorations for Lilypond.

## Support Libraries

* [assert](https://github.com/lyp-packages/assert) - Assertions for Lilypond packages.
* [lys](https://github.com/lyp-packages/lys) - Run Lilypond as a server.

## Tweaking

* [merge-rests](https://github.com/lyp-packages/merge-rests) - Rest merging engraver.
* [super-shape-me](https://github.com/lyp-packages/super-shape-me) - Slur & tie tweaking for Lilypond.
* [auto-extenders](https://github.com/lyp-packages/auto-extenders) - Automatic lyrics line extenders for Lilypond.

# Contributing

This repository contains a YAML index of Lilypond packages that can be installed using [lyp](https://github.com/noteflakes/lyp), the Lilypond package manager.

To add your package to the index:

1. Fork this repository
2. Add your package to <code>index.yml</code> under the <code>packages</code>, using the following format:

```yaml
packages:
  <package-name>:
    url: <public git url>
    description: <short description>
    author: <author>
```

3. Add your package to this README file under the proper section (or possibly create a new section).
4. Submit a pull request

## The rules

1. The package name must be unique, the packages in the index file should be ordered alphabetically.
2. The git url could be a github repository id (i.e. <code>userid/mypackage</code>), a partially-qualified URL (i.e. <code>acme.com/myrepo.git</code>), or a fully-qualified URL (i.e. <code>https://github.com/blah/blah.git</code>)
2. The package should include a <code>package.ly</code> file in its root directory. This is the entry point for the package.
3. Additional <code>.ly</code> files can be included using relative <code>\include</code>s.
4. The package should have a README and include a license, either as part of the code, in the README, or in a separate file.
5. Transitive dependencies are defined as usual using <code>\require</code>.
6. The package repository should be versioned using git tags. Version tags can be optionally prefixed with <code>v</code> (for example <code>v0.2</code>).
7. Including the package in the index is optional. It allows users to install your package using a short unique name, but your package could always be installed using its publicly-accessible git URL.