---
title: News
---

# lyp - Use Lilypond Like a Boss!

The power of [Lilypond](http://lilypond.org/), without the pain: <b><a href="#" router-link="/user-guide?id=working-with-packages">Install packages</a></b> to enhance your Lilypond files with additional functionality, like <a href="#" router-link="/packages?id=tweaking">specialized tweaks</a> or <a href="#" router-link="/packages?id=fonts">alternative music fonts</a>. <b><a href="#" router-link="/user-guide?id=installing-and-using-lilypond">install Lilypond</a></b> with a single easy command. <b><a href="#" router-link="/user-guide?id=lyp-watch">Automatically recompile</a></b> your files, flatten include files and <a href="#" router-link="/user-guide">more</a>.

```bash
$ gem install lyp
$ lyp install lilypond@unstable
```

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

