## Dependencies ##
`/project-dir/config/modules.lua`
 
Create this file to select which runtime modules to import.  
It should be a Lua script that returns an array of strings.  
Each array value should be the path to a folder, relative to the monorepo root.

#### Example ####
```
return {
    "my-wc3-libs/helper",
    "my-wc3-libs/cam-lib"
}
```
<br/>




### Creating Modules ###
If a project imports a module, it'll parse through all top-level files in its folder.  
Files that start with one of these prefixes are automatically handled by the build process.  
Exception: Module folders that start with an underscore won't be parsed for prefixes.
- **g**:
    In this file, global Lua variables used by that module should be initialized.  
    This script is automatically executed at runtime in compiled maps.
- **a**:
    In this file, custom abilities used by that module should be defined using `compiletime`
    (see [Ceres Docs](https://github.com/ceres-wc3/ceres-lua-template/blomaster/src/main.lua)).  
    These custom abilities are automatically added to compiled maps.
- **u**:
    In this file, custom units used by that module should be defined using `compiletime`
    (see [Ceres Docs](https://github.com/ceres-wc3/ceres-lua-template/blob/master/src/main.lua)).  
    These custom units are automatically added to compiled maps.
- **f**:
    This file should be a FDF file that defines custom UI Frames used by this module.  
    A TOC file with these custom UI Frames is automatically generated and injected, then loaded at runtime.

#### Module Imports ####
Create `imports.lua` in the top level of a module folder
if it needs to inject files or directories into compiled MPQ mapfiles.  
It should follow the same format as [`/project-dir/config/imports.lua`](imports.lua.md).
