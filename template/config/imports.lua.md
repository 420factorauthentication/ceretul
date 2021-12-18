## MPQ File Imports ##
`/project-dir/config/imports.lua`

Create this file to choose files or directories to inject into compiled MPQ mapfiles.  
It should be a Lua script that returns an array.  
Each value in that array should be another array with one or two strings:
- First string: The path to the file or directory to import, relative to the monorepo root.
- Second string (optional): The path the import will have inside the MPQ mapfile.  
  If missing, uses the same path as the first string.

#### Example ####
```
return {
    {"my-project/assets"},
    {"my-art-lib/icons/GoldMine.tga"},
    {"my-wc3-libs/ui-lib/fonts/comic-sans-ms", "assets/fonts/comic-sans-ms"},
    {"my-art-lib/bg/Cathedral.tga", "assets/bg/Cathedral.tga"}
}
```
