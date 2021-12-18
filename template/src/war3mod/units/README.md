## Custom Unit Definitions ##
`/project-dir/src/war3mod/units/`

Create new scripts here that define custom units
using `compiletime` (see **[Ceres](https://github.com/ceres-wc3/ceres)** docs).  
All top-level Lua files in here are automatically executed.

#### Order of Execution ####
1. war3mod (abilities, FDFs, units)
2. objects
3. triggers
4. main
