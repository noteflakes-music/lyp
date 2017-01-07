## What is a package?

In lyp, a package is a directory that should contain at least a single Lilypond file named `package.ly` in its root directory. A package could contain additional Lilypond and Scheme files referenced in the main package file (using relative `\include`s). A package could also depend on other packages by using the `\require` command.

lyp packages are expected to be published as git repositories. The package is then versioned using git tags. A package can be referenced either using its git URL, a registered canonical name (if it's registered in the [lyp package index](https://github.com/lyp-packages/index)), or alternatively as a local path (which is really meant for package development more than anything else).

## Creating a package

To create a Lilypond package:

- Create a git repository.
- Add a `package.ly` file, which is the main entry point for your package.
- Optionally add additional Lilypond files or package dependencies.
- Test & debug your code (see <a href="#" jump-to-id="testing-packages">below</a>).
- Publish your package (see <a href="#" jump-to-id="publishing-packages">below</a>).

To test your package with an actual input file, you can install it from a local path (for more on testing see <a href="#" jump-to-id="testing-packages">below</a>). Suppose your package is at ~/repo/mypack:

```bash
$ lyp install mypack@dev:~/repo/mypack
# or alternatively:
$ lyp install --dev mypack:~/repo/mypack
```

This will create a `mypack@dev` package referencing your local files, which you can then reference normally from an input file using the `\require` command:

```lilypond
\require "mypack@dev"
```

If the input file is residing inside your package (for example, <a href="#" jump-to-id="testing-packages">test files</a>), you can require your package by specifying a relative path. Suppose the input file is at `mypack/test/mypack_test.ly`:

```lilypond
\require "mypack:.."
```

## The package loading process

When compiling a file using lyp (using either `lyp compile` or `lilypond`), the following steps are taken:

- lyp performs a static analysis of the given source file and any include files to find dependencies expressed using the `\require` command.
- Any required package is also analyzed for transitive dependencies.
- A dependency graph is generated, and the best available (i.e. installed) version is selected for each dependency.
- A wrapper script is created, loading the lyp <a href="#" jump-to-id="scheme-api">Scheme API</a> and defining Scheme variables containing the locations of all dependencies, and related info. The wrapper script finally `\include`s the user's main source file.
- When a `\require` command is executed, the location of the package's entry point (the `package.ly` file) is looked up and loaded. Before including the package's main file, lyp sets various variables in order to provide the package with a sensible environment.

## Including files

lyp provides the `\pinclude` and `\pincludeOnce` commands for including files residing in the current package using relative paths. The `\pincludeOnce` commands loads a given file only once:

```lilypond
\pinclude "inc/template.ily"
\pincludeOnce "inc/init.ily"
```

lyp also defines a `lyp:load` Scheme function for loading Scheme files using relative paths without adding directories to the `%load-path`:

```lilypond
#(if (not (defined? 'mypack:init))(lyp:load "scm/init.scm"))
```

Loading Scheme files that way is a better technique than adding directories to `%load-path`, because this way one avoids possible name clashes, which may lead to unexpected behavior.

## Conditional includes

Files can also be included conditionally by evaluating a Scheme expression using the `\pcondInclude` and `\pcondIncludeOnce` commands:

```lilypond
% include edition-specific tweaks
\pcondInclude #(eq? edition 'urtext) "urtext_tweaks.ly"
```

# Transitive Dependencies

Any lyp package can depend on one or more other packages, which in turn can depend on others still. lyp can handle dependency trees of arbitrary depth, and even circular dependencies. For example, the [Bravura](https://github.com/lyp-packages/bravura) and [Gootville](https://github.com/lyp-packages/gootville) font packages both depend on the [smufl](https://github.com/lyp-packages/smufl) package, which provides common functionality for all [SMuFL](http://www.smufl.org/) fonts.

To express a dependency, packages use the same `\require` command used in user files. See the <a href="#" router-link="/?id=using-packages">user guide</a> for more information.

### Including fonts

lyp also supports automatic installation of fonts, based on work by [Abraham Lee](https://github.com/tisimst). When a package is installed, lyp will copy any font files residing in the `fonts` directory into the corresponding `otf` and `svg` directories of all installed versions of Lilypond.

**Note**: fonts will be only installed in versions of Lilypond starting from than 2.18.2. lyp automatically patches any version newer than 2.19.12 in order to support custom fonts.

### Extending lyp and adding commands

A package can also be used to extend or override lyp's stock functionality or add more features and commands. Extensions are written in Ruby in a file named `ext.rb` placed in the package's main directory. An extension can be used to either perform a certain action when the package is installed, or be loaded each time lyp is invoked.

When a package is installed, lyp executes the code in `ext.rb`. To make the extension run each time lyp is invoked, the extension should include the following line:

```ruby
lyp.install_extension(__FILE__)
```

More commands can be added to lyp's command line interface by adding methods to the `lyp::CLI` class using the [Thor](https://github.com/erikhuda/thor/wiki/Method-Options) API. For example:

```ruby
class lyp::CLI
  desc "count", "show package count"
  def count
    packages = lyp::Package.list_lyp_index("")
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

A test file can either be a simple Lilypond file which includes the package files and results in a Lilypond score, or a Lilypond file that performs unit tests on Scheme code.

For more information on testing, see the [lyp-assert](https://github.com/lyp-packages/assert) package, which is meant to be used for unit testing Lilypond code, and serves as an example of how to test a package.

### Publishing packages

In order for your package to be available to all users, you'll need to first push your code to a publically accessible git repository (for example on github). Users will then be able to install your package by using the git URL of the public repository.

You can also add your package to the lyp [public package index](https://github.com/lyp-packages/index), by cloning it, editing [index.yaml](https://github.com/lyp-packages/index/blob/master/index.yaml), and creating a pull request.

## Scheme API

lyp provides loaded packages with a Scheme API in order to facilitate handling relative paths and loading of Lilypond include files and Scheme files.

### General

All Scheme variables and functions provided by lyp are namespaced, using the `lyp:` prefix.

### Variables

Before a package is loaded using its main entry point in the `package.ly` file, lyp sets the following variables:
 
- `lyp:cwd` - the current working directory (reported by lyp)
- `lyp:input-filename` - the absolute path of the input file
- `lyp:input-dirname` - the absolute path of the input file's directory
- `lyp:current-package-dir` - currently equal to `lyp:cwd`

### Procedures

In addition to the above commands, lyp also provides a few utility Scheme procedures:

- `lyp:join-path` joins multiple strings into a complete path:

```scheme
(lyp:join-path "a" "b" "c") ;=> "a/b/c"
```

- `lyp:normalize-path` converts backslashes to forward slashes:

```scheme
(lyp:normalize-path "my\windows\path") ;=> "my/windows/path"
```

- `lyp:split-path` splits a path into its parts:

```scheme
(lyp:split-path "my/super/path") ;=> '("my" "super" "path")
```

- `lyp:absolute-path?` returns `#t` if the given path is absolute:

```scheme
(lyp:absolute-path? "/my/absolute/path") ;=> #t
```

- `lyp:expand-path` returns an absolute path for the given path (relative to the current working directory):

```scheme
(lyp:expand-path "relative/path") ;=> "/my/current/directory/relative/path"
```

- `lyp:load` loads a Scheme source file using a relative path:

```scheme
(lyp:load "src/wow.scm")
```

- `lyp:include` loads a lilypond include file using a relative path:

```scheme
(lyp:include "src/my.ly")
```

- `lyp:finalize` adds a Scheme proc to be called after the user's file has been processed.

```scheme
(lyp:finalize (lambda () (display "we're done!\n")))
```

(For example usage see the [assert](https://github.com/lyp-packages/assert/blob/master/assert.scm) package).

## Contributing to lyp

lyp is written in Ruby, and its code is [available on github](https://github.com/noteflakes/lyp). To hack on it, simply clone the repository. To run the specs:

```bash
$ cd lyp
$ bundle install # needs to be run only once
$ rspec
```

Please feel free to submit issues and pull requests.
