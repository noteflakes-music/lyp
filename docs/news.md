---
title: News
---

# lyp - Use Lilypond Like a Boss!

## The power of [Lilypond](http://lilypond.org/), without the pain

<b><a href="#" router-link="/user-guide?id=working-with-packages">Install packages</a></b> to enhance your Lilypond files with additional functionality, like <a href="#" router-link="/packages?id=tweaking">specialized tweaks</a> or <a href="#" router-link="/packages?id=fonts">alternative music fonts</a>. <b><a href="#" router-link="/user-guide?id=installing-and-using-lilypond">install Lilypond</a></b> with a single easy command. <b><a href="#" router-link="/user-guide?id=lyp-watch">Automatically recompile</a></b> your files, flatten include files and <a href="#" router-link="/user-guide">more</a>.

```bash
$ gem install lyp
$ lyp install lilypond@unstable
$ lilypond mymusic.ly
```

<hr/>

## No More Self-Contained Releases, for the Time Being

_2018/3/13_

Up until now, there have been two ways to install lyp: as a Ruby gem, and as a self-contained embedded ruby installation (for those who do not have Ruby installed on their system).

Unfortunately, packaging lyp into a self-contained release proved problematic, as it made it impossible to use a more recent version of Ruby and other dependencies.

Therefore, for the time being new versions of lyp will be released only as Ruby gems. The self-contained releases will always be there, but will no longer be supported.

<hr/>

## A Better Interface for Loading Packages and Files

_2018/2/20_

One of the main goals for lyp is to let Lilypond users easily structure their Lilypond code in a modular way. Separating different parts of your notation project - specific instruments or movements - into separate files, makes it easier to enter and edit the music, especially for large musical projects.

In order to further facilitate working with modular code, we've introduced new commands for requiring and including files. These commands remove some of the ambiguity around the old commands such as `\pinclude`. They also are prefixed so as to show they come from lyp and not from Lilypond, and provide a richer functionality. The old commands are still there, but are deprecated and will eventually be removed in the future.

Over the coming weeks We'll be updating the docs to include the new commands and how they're used. For now, here is a summary of the changes:

### \require

`\require` has become `\lyp-require`. It can now also accept a list of packages to load, e.g. `\lyp-require #'(assert oll-core auto-extenders edition engraver)`.

### \pinclude

`pinclude` has become `\lyp-load`. It accepts file references without extension (it will look for both `.ly` and `.ily` matches), directory references (for loading all files in a directory), and even wildcard patterns (for example `\lyp-load "lib/**/*.ly"` will load all files in any subdirectory under `lib`)

### \pincludeOnce

`pincludeOnce` has become `lyp-include`. This makes more sense, as most of the time you'll need to include a file only once. If you need to repeatdly include a file (perhaps containing a recurrent musical phrase), you can always use `\lyp-load`.

### \pcondInclude and \pcondIncludeOnce

Both `\pcondInclude` and `\pcondIncludeOnce` are deprecated. Judging from the currently available packages, their use is minimal. If you need this functionality, you'll have to wrap your includes and requires with a scheme expression. For example, the following:

```lilypond
\pcondInclude #(is-it-true?) "myfile.ly"
```

Should be changed to:

```lilypond
#(if (is-it-true?)
  (lyp:load:ref "myfile.ly" #f)
)
```

For `\pcondIncludeOnce` you should change the second argument to `lyp:load:ref`:

```lilypond
#(if (is-it-true?)
  (lyp:load:ref "myfile.ly" #t)
)
```

Stay tuned as we update the documentation to reflect the changes. We'll also make updates to the existing packages to use the new API.

<hr/>

## New release for lyp

_2018/2/5_

It's been a year since I last worked on lyp. Fortunately, some people still care about it and have brought some [issues](https://github.com/noteflakes/lyp/issues) to my attention. I've been able to help some of them and have just put out a new release. Also, in the last few days the old Lilypond binaries download link has stopped working. I've updated lyp to download from the new location (on the lilypond.org website). So you should update your lyp installation to the latest version - 1.3.8. Here are some of the changes since 2017:

- Fix Lilypond installation link (the  http://download.linuxaudio.org/lilypond links don't work anymore).
- Fix installation of non-registered github packages (#54).
- Set default encoding to UTF-8 (#52).
- Fix Lilypond install on Windows.
- Accept symbol arguments for require, include commands (#49).
- Improve docs.
- Add `--svg` command line option (#50).
- Improve Lilypond commandline option parsing.
- Remove non-functional `--open` switch.
- Improve error reporting (print backtrace only when `--verbose` is specified).
- Add `--music`/`--music-relative` command line switch for quickly entering music on the command line (#47).

You can install lyp by running `gem install lyp`.

<hr/>

## Installing Lilypond with lyp

_2017/1/15_ 

Whether you're using Lilypond for the first time, or am a seasoned Lilypond veteran and want to upgrade to the latest version of Lilypond, lyp is there to help you. Install lyp on your machine and you're basically free to use any available version of Lilypond (for more information on installing lyp consult the <a href="#" router-link="/user-guide?id=installation">user guide</a>):

```bash
$ gem install lyp
```

Once lyp is installed you can consult the list of available versions. Let's check the stable versions:

```bash
$ lyp search lilypond@stable

Available versions of lilypond@stable:

   2.8.8
   2.10.0
   2.10.33
   ...
   2.18.2

```

What about unstable versions?

```bash
$ lyp search lilypond@unstable

Available versions of lilypond@unstable:

   2.17.0
   ...
   2.19.53
   2.19.54
```

Let's install the latest unstable version:

```bash
$ lyp install lilypond@unstable
Installing version 2.19.54
Extracting...
Copying...
GNU LilyPond 2.19.54

Copyright (c) 1996--2015 by
  Han-Wen Nienhuys <hanwen@xs4all.nl>
  Jan Nieuwenhuizen <janneke@gnu.org>
  and others.

This program is free software.  It is covered by the GNU General Public
License and you are welcome to change it and/or distribute copies of it
under certain conditions.  Invoke as `lilypond --warranty' for more
information.
```

And that's it! No need to open a browser, visit the Lilypond website and click on download links. Just `lyp install lilypond` and you're done. How about installing any old version as you go?

```bash
$ lilypond -nu2.19.37 myfile.ly
GNU LilyPond 2.19.37
... 
```

Let's show all installed versions of Lilypond currently on the machine:

```bash
$ lyp list lilypond

Lilypond versions:

   2.18.2
 * 2.19.53
=> 2.19.54

# => - current
# =* - current && default
#  * - default
```

__Summary__: lyp takes the pain out of installing Lilypond. you can have as many versions of Lilypond installed on your machine as you wish, and the latest one is only a single simple command away.

<hr/>

