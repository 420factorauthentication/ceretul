## Precompile Specs ##
`/project-dir/config/precompile.lua`

**Not Implemented Yet**  
Create this file to select tests to run before maps are compiled.  
It should be a Lua script that returns an array of strings.  
Each string should be a path to a Lua script, relative to the monorepo root.  
Outputs logs in *TBD*.  

#### Example ####
```
return {
    "my-project/spec/VariableTest.lua",
    "my-wc3-libs/math-lib/spec/VectorTest.lua"
}
```
