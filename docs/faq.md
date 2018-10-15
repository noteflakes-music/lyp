# FAQ

#### Does Lilypond really need packages?

Yes! Before lyp, Lilypond users had now better way to share code than to post it on [lilypond-user](http://lilypond.1069038.n5.nabble.com/User-f3.html), on [LSR](http://lsr.di.unimi.it/LSR/Search), or just pass some files around.

With lyp, sharing libraries of arbitrary complexity becomes almost trivial. End users don't need to keep track of any third-party code they downloaded from the internet. Instead, they specify dependencies with an easy `\require` command. And because packages are versioned, end users can ensure their files will continue to compile in the future, on any machine.
 
Package publishers also benefit by not having to pack their code themselves, but instead simply offer it as a git repository (see also below).

#### Why are packages published as git repositories?

Authoring packages as git repositories provides a solution for many of the problems associated with package management. Firstly, using git provides an excellent vehicle for distribution. By using any of the freely available git hosting services, your package is immediately published and updated without any effort on your part. Since git repositories have URLs, its easy to reference packages.
 
In addition, packages can be versioned using git tags. This allows users to use specific versions of packages, while removing much of the infrastructure required for updating and keeping track of package versions.
 
If we were not to use git for distribution and versioning of packages, we would have needed to setup a whole system dedicated to hosting and managing packages, which would be a substantial undertaking. Git provides us with a wonderful, lightweight, effortless solution.

#### Is lyp related to the [OpenLilyLib](https://github.com/openlilylib/snippets) project?

No. OpenLilyLib is a collection of a lot of different things - editorial tools, tweaking tools, examples of various techniques, and some low-level plumbing designed to provide some kind of package-like functionality. Despite the efforts of the OpenLilyLib authors, the code remains a bit of a mess, and the package-related stuff fails to deliver a real solution to package management.

Nevertheless, we at Noteflakes have started the work of turning the many gems hidden inside OpenLilyLib into actual lyp packages. There's currently [oll-core](https://github.com/lyp-packages/oll-core), which provides common low-level functionality to all OpenLilyLib packages, [oll-ji](https://github.com/lyp-packages/oll-ji), which provides tools for notating just-intonation, and a few other specialized packages. We hope to be able to port the majority of OpenLilyLib to lyp packages in 2017.

#### Why not use Lilypond itself to provide package management?

Lilypond can do many things well, and the bundled Guile Scheme scripting language is useful. However, Lilypond is limited in some regards. For example, to be able to dynamically load dependencies from arbitrary locations (without specifying those locations in advance) would require patching Lilypond. This means that whenever a new version of Lilypond is installed, it would need to be patched.
 
In addition, Scheme seems to lack many of the string-manipulation and file APIs provided in modern scripting languages, that would make it more difficult to create a flexible, sophisticated package manager that could for example calculate dependency graphs of arbitrary depth, or pull git repositories and perform various git operations.

In our analysis, it was better to create an external, completely independent tool that would _wrap_ Lilypond instead of patch it. That way, we are not dependent on any functionality provided by Lilypond itself, and are better protected against changes introduced in newer Lilypond versions.
