<p align="center">
  <a href="https://travis-ci.org/noteflakes/lyp"><img src="https://travis-ci.org/noteflakes/lyp.svg?branch=master"></a>
</p>
<p align="center">
  <a href="https://github.com/lyp-packages/index#readme">The lyp package index</a>
</p>

# lyp - The Lilypond Swiss Army Knife

lyp is an open-source tool that takes the pain out of working with [Lilypond](http://lilypond.org/).

__Use packages__: Install [packages](http://noteflakes.github.io/lyp/#/?id=working-with-packages) to enhance your Lilypond files with additional functionality. Add [specialized tweaks](http://noteflakes.github.io/lyp/#/packages?id=tweaking) or even [change the music font](http://noteflakes.github.io/lyp/#/packages?id=fonts).

__No hassle Lilypond installation__: with lyp you can [install Lilypond](http://noteflakes.github.io/lyp/#/?id=installing-and-using-lilypond) with a single easy command, no need to click links, or unzip and copy files around.

__Even more tools for power users__: watch and automatically [recompile](http://noteflakes.github.io/lyp/#/?id=lyp-watch) changed source files, [flatten](http://noteflakes.github.io/lyp/#/?id=lyp-flatten) include files, and [automatically install](http://noteflakes.github.io/lyp/#/?id=lyp-compile) package dependencies or any required version of Lilypond.

For more information, see the lyp [documentation](http://noteflakes.github.io/lyp/).

## Contributing

Lyp is written in Ruby, and its code is [available on github](https://github.com/noteflakes/lyp). To hack on it, simply clone the repository. To run the specs:

```bash
$ cd lyp
$ bundle install # needs to be run only once
$ rspec
```

Please feel free to submit issues and pull requests.
