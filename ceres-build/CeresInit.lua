--== < Libraries > ==--
local libHelper = require "ceres-build/LibHelper"

--== < Constants > ==--
local projDir = ceres.getScriptArgs()[1]
local pathSeparator = package.config:sub(1,1)



-------------------------------------
-- Global Ceres Vars - Init Layout --
-------------------------------------
ceres.layout.mapsDirectory = pathSeparator
ceres.layout.targetDirectory = libHelper.formPath(projDir, "target") .. pathSeparator
ceres.layout.srcDirectories = {}

local srcDirectories = {
    -- projDir,
    -- libHelper.formPath(projDir, "src"),
    -- libHelper.formPath(projDir, "config"),
    -- libHelper.formPath(projDir, "target"),

    -- libHelper.formPath(projDir, "src", "core"),
    libHelper.formPath(projDir, "src", "core", "main"),
    libHelper.formPath(projDir, "src", "core", "objects"),
    libHelper.formPath(projDir, "src", "core", "triggers"),

    -- libHelper.formPath(projDir, "src", "war3mod"),
    libHelper.formPath(projDir, "src", "war3mod", "abils"),
    libHelper.formPath(projDir, "src", "war3mod", "units"),
    
    "ceres-runtime",
    libHelper.formPath(projDir, "target", "_build"),
}

for k, v in pairs(srcDirectories) do
    if (fs.isDir(v)) then
        table.insert(ceres.layout.srcDirectories, v)
    end
end



------------------------------------------
-- Global Ceres Vars - Init War3 Launch --
------------------------------------------
if (fs.exists("runconfig.lua")) then
    print("\n\n\n--== " .. "BUILD CONFIG" .. " ==--")
    print("> SUCCESS: Detected repo file \"runconfig.lua\". Applying settings...")
    require("runconfig")
end
