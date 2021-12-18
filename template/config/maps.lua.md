## Compiling Maps ##
`/project-dir/config/maps.lua`

Create this file to pick which mapfiles to process and recompile.  
It should be a Lua script that returns an array of strings.  
Each string should be a path to a mapfile, relative to the monorepo root.

#### Example ####
```
return {
    "my-project/maps/TerrainFlat.w3x",
    "my-map-lib/MedievalKingdom.w3x"
}
```
