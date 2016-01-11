## DOCS

- Well, everything!

## install self

- Check that install self works correctly. Ideally add a spec.
- Refuse to install self if `which lyp` = `"~/.lypack/bin/lyp"`

## bin/lilypond

- Upon running, check that default/current lilypond is valid. If not, reset the default and current.

## install <package>

- Install from local git URL: `lyp install file://path/to/repo`
- Install package under development: `lyp install oll@dev:<path>`
  (This will create a symlink to `<path>` at `~/.lyp/packages/oll@dev`)
    
  Other options:
  `lyp install oll@dev:.`
  
## Missing commands:

- `resolve <lilypond file>` - installs all packages found in user's files
- `which <package>` 
- `which lilypond`

