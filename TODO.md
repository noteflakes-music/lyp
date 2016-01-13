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
  
- In fact, we can generalise this into a way to install packages from local files:

  `lyp install oll@<version>:<file path>`
    
  lyp then creates the package directory inside ~/.lyp/packages and creates a `package.ly` containing an include statement referencing the given path.
  
  - If the path is a directory, lyp searches for a `package.ly` file, emitting an error if not found.
  - If the path is a file, lyp considers this file the entry point for the package.


