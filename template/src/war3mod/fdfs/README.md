## Custom FDF Definitions ##
`/project-dir/src/war3mod/ui/`

Create new FDF files here that define custom UI Frames.

A TOC file is automatically generated that includes all top-level FDF files in here.  
The FDF files and TOC file are automatically injected into compiled MPQ mapfiles.  
The TOC file is automatically loaded at runtime.

#### Order of Execution ####
1. war3mod (abilities, FDFs, units)
2. objects
3. triggers
4. main
