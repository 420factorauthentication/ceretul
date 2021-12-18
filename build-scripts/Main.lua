--== < Libraries > ==--
local libBuild = require "build-scripts/LibBuild"

--== < Constants > ==--
local projDir = ceres.getScriptArgs()[1]
require "build-scripts/CeresInit"



-----------------
-- BUILD SPECS --
-----------------
if not (fs.exists(projDir)) then
    print(" > ERROR: proj-dir doesn't exist! Exiting... ")
    return
end



------------------
-- BUILD CONFIG --
------------------
libBuild.logHeader("BUILD CONFIG")
local args = libBuild.getFormattedBuildArgs()



--------------------
-- PROJECT CONFIG --
--------------------
libBuild.logHeader("PROJECT CONFIG")
local imports     = libBuild.parseProjConfigFile("imports.lua")
local maps        = libBuild.parseProjConfigFile("maps.lua")
local modules     = libBuild.parseProjConfigFile("modules.lua")
local precompiles = libBuild.parseProjConfigFile("precompile.lua")
local runtimes    = libBuild.parseProjConfigFile("runtime.lua")



---------------------
-- RUNTIME MODULES --
---------------------
libBuild.logHeader("RUNTIME MODULES")
local modFiles = libBuild.getRuntimeModuleFiles(modules)



-------------------------
-- RUNTIME SOURCE CODE --
-------------------------
libBuild.logHeader("RUNTIME SOURCE CODE")
local srcAbils   = libBuild.parseWarDir("abils")
local srcUnits   = libBuild.parseWarDir("units")
local srcObjs    = libBuild.parseCoreDir("objects")
local srcTrigs   = libBuild.parseCoreDir("triggers")
local srcMains   = libBuild.parseCoreDir("main")
local srcImports = libBuild.parseSrcFrames()
for k, v in pairs(srcImports) do imports[k] = v end
libBuild.generateRuntimeMain(modFiles.globals, modFiles.abils, modFiles.units, srcAbils, srcUnits, srcObjs, srcTrigs, srcMains)



-------------------
-- BUILD PROCESS --
-------------------
libBuild.logHeader("BUILD PROCESS")
libBuild.compileMaps(maps, imports, args)
libBuild.logHeader("BUILD COMPLETE!")
