## Runtime Specs ##
`/project-dir/config/runtime.lua`

**Not Implemented Yet**  
Create this file to select tests to run at map runtime in compiled maps.  
It should be a Lua script that returns an array of strings.  
Each string should be a path to a Lua script, relative to the monorepo root.  
Outputs logs in *TBD*.  

#### Example ####
```
return {
    "my-project/spec/UnitTest.lua",
    "my-wc3-libs/cam-lib/spec/CamSetupTest.lua"
}
```
