# Ceretul #
**Ceretul** is a monorepo of Warcraft III map projects built
using **[Ceres](https://github.com/ceres-wc3/ceres)**. It includes build scripts that
that automatically detect, parse, and include files in specific folders:
- Main runtime source code
- Assets (images, audio files, etc)
- Global runtime variables used by dependencies
- Custom map data (abilities, FDFs, units, etc)

#### Creating New Map Projects ####
Create a new folder in this monorepo. See the **[template](template/README.md)**.
<br/><br/><br/>



## Build Process ##
`ceres build [project-dir] [args ...]`

Run this command from the root directory of this monorepo.

Each project is configured to take an MPQ mapfile, inject new sourcecode and assets, then compile a new MPQ mapfile.
A project can be configured to do this to multiple mapfiles.

Output maps are found in `/project-dir/target/`.

#### Build Args ####
-  `d`: Delete existing output directory map before compiling new one, to cleanse old files after changing imports.  
-  `r`: After building, start Warcraft 3 running the last successfully compiled map. 

#### Run Config ####
Create `runconfig.lua` in the top level of the monorepo to add CLI flags when launching Warcraft 3 to test maps.

This file should be a Lua script that sets values in `ceres.runConfig` and doesn't need to return anything.

This file generally configures parameters relative to the current computer, and is excluded from the repo.

See [Ceres Docs](https://github.com/ceres-wc3/ceres-lua-template/blob/master/runconfig.lua) for more details.
<br/><br/><br/>



## Ceres Notes ##
- Ceres sets LUA_PATH to include `"?.lua"` but not `"?"`. Leave out the file
  extension when using `require`.
- Most Ceres filesystem functions that take a path (ex: `fs.readDir`) work with
  both relative and absolute paths.
