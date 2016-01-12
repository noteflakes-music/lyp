## DOCS

- Well, everything!

## install self

- Check that install self works correctly. Ideally add a spec.
- Refuse to install self if `which lyp` = `"~/.lypack/bin/lyp"`

## install <package>

- Install from local git URL: `lyp install file://path/to/repo`
- Install package under development: `lyp install oll@dev:<path>`
  (This will create a symlink to `<path>` at `~/.lyp/packages/oll@dev`)
    
  Other options:
  `lyp install oll@dev:.`
  

