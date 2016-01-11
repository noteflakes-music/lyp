## DOCS

- 

## install self

- Check that install self works correctly. Ideally add a spec.
- Refuse to install self if `which lyp` = `"~/.lypack/bin/lyp"`

## bin/lilypond

- Upon running, check that default/current lilypond is valid. If not, reset the default and current.

## CLI

- Switch from commander to thor or maybe find something better?

## install <package>

- When installing without a version specifier, instead of installing head (of master), install the highest version found in tags. Only if no numerical versions are found, install head.
- Install from local git URL: `lyp install file://path/to/repo`
- Install package under development: `lyp install oll@dev:<path>`
  (This will create a symlink to `<path>` at `~/.lyp/packages/oll@dev`)


## Missing commands:

- `resolve <lilypond file>` - installs all packages found in user's files
- `uninstall <package>` - 
- `which <package>` 
- which lilypond

