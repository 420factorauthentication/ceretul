--===============--
local libBuild = {}
--===============--

--== < Libraries > ==--
local libHelper = require "build-scripts/LibHelper"



--==========================================--
-- logHeader()                              --
--   header: string                         --
--                                          --
-- Formats and prints a log header message. --
--==========================================--
libBuild.logHeader = function(header)
    print("\n\n\n--== " .. header .. " ==--")
end



--============================================================================================================--
-- getFormattedBuildArgs()                                                                                    --
--                                                                                                            --
-- Gets a table of optional CLI args passed to Ceres build command.                                           --
-- Format:  key = arg,  value = true or nil                                                                   --
--                                                                                                            --
-- Optional CLI Args:                                                                                         --
-- d: Delete existing target directory before compiling new one, to cleanse old files after changing imports. --
-- r: After building, start Warcraft 3 running the last successfully compiled map.                            --
--============================================================================================================--
libBuild.getFormattedBuildArgs = function()
    local formattedArgs = {}
    local input = ceres.getScriptArgs()
    local numMandatoryScriptArgs = 1
    local optionalScriptArgs = {"d", "r"}

    for i=(1+numMandatoryScriptArgs), (#input) do
        for k, v in pairs(optionalScriptArgs) do
            if (v == input[i]) then
                formattedArgs[v] = true
                print("> SUCCESS: Parsing CLI arg \'" .. v .. "\'")
                optionalScriptArgs[k] = nil
                break
            end
        end
    end

    return formattedArgs
end



--=======================================--
-- parseProjConfigFile()                 --
--   configFile: string                  --
--                                       --
-- Parses a file in 'proj-dir/config/'.  --
-- Returns a table.                      --
-- See 'template/config/' for more info. --
--=======================================--
libBuild.parseProjConfigFile = function(configFile)
    local projDir = ceres.getScriptArgs()[1]
    local path = libHelper.formPath(projDir, "config", configFile)
    local output = libHelper.parseOutputScript(path) or {} 
    if (#output > 0) then
        print("> SUCCESS: Detected config file \"" .. configFile .. "\". Parsing output...")
    end
    return output
end



--===========================================================--
-- parseCoreDir()                                            --
--    folderName: string                                     --
--                                                           --
-- Parses a folder in 'proj-dir/src/core/'.                  --
-- Returns a table of Lua scriptnames to require at runtime. --
-- See 'template/src/core/' for more info.                   --
--===========================================================--
libBuild.parseCoreDir = function(folderName)
    local projDir = ceres.getScriptArgs()[1]
    local folderPath = libHelper.formPath(projDir, "src", "core", folderName)
    local absFilePathsNoSuffix = libHelper.readDirFilesWithSuffix(folderPath, ".lua", false)
    local output = {}

    if ((type(absFilePathsNoSuffix) == "table") and (#absFilePathsNoSuffix > 0)) then
        print("> SUCCESS: Detected Lua scripts in \"" .. folderName .. "\". Parsing scripts...")
        for k, v in pairs(absFilePathsNoSuffix) do
            table.insert(output, v:sub(libHelper.getLowestLevelStart(v)))
        end
    end

    return output
end



--===========================================================--
-- parseWarDir()                                             --
--   folderName: string                                      --
--                                                           --
-- Parses a folder in 'proj-dir/src/war3mod/'.               --
-- Returns a table of Lua scriptnames to require at runtime. --
-- See 'template/src/war3mod/' for more info.                --
--===========================================================--
libBuild.parseWarDir = function(folderName)
    local projDir = ceres.getScriptArgs()[1]
    local folderPath = libHelper.formPath(projDir, "src", "war3mod", folderName)
    local absFilePathsNoSuffix = libHelper.readDirFilesWithSuffix(folderPath, ".lua", false)
    local output = {}

    if ((type(absFilePathsNoSuffix) == "table") and (#absFilePathsNoSuffix > 0)) then
        print("> SUCCESS: Detected Lua scripts in \"" .. folderName .. "\". Parsing scripts...")
        for k, v in pairs(absFilePathsNoSuffix) do
            table.insert(output, v:sub(libHelper.getLowestLevelStart(v)))
        end
    end

    return output
end



--=========================================================================--
-- getRuntimeModuleFiles()                                                 --
--   modules: table[strings]                                               --
--                                                                         --
-- Takes a table of paths to runtime modules used by this project.         --
-- Fetches all of their runtime init scripts, MPQ imports, and FDFs.       --
-- Generates a TOC file: 'proj-dir/target/_build/libFrames.toc'            --
-- Returns a table with subtables of runtime scripts and MPQ file imports. --
-- See 'template/config/modules.lua.md' for more info.                     --
--=========================================================================--
libBuild.getRuntimeModuleFiles = function(modules)
    local pathSeparator = package.config:sub(1,1)
    local tocBuffer  = ""
    local modFiles   = {}
    modFiles.globals = {}
    modFiles.abils   = {}
    modFiles.units   = {}
    modFiles.imports = {}

    -- Parse each module --
    for k1, v1 in pairs(modules) do
        if (fs.exists(v1)) then
            print("> SUCCESS: Parsing module \"" .. v1 .. "\"")

            -- Get files needed to init libraries --
            local currModFiles = fs.readDir(v1)
            local folderName = v1:sub(libHelper.getLowestLevelStart(v1))
            local rootLen = fs.absolutize(v1):len() + pathSeparator:len()
            local luaSuffix = ".lua"

            if ((type(currModFiles) == "table") and (folderName:sub(1,1) ~= "_")) then
                for k2, v2 in pairs(currModFiles) do
                    local gPrefix = v2:find("g", rootLen)
                    local aPrefix = v2:find("a", rootLen)
                    local uPrefix = v2:find("u", rootLen)
                    local fPrefix = v2:find("f", rootLen)
                    local fileName = v2:sub(rootLen + 1)
                    local fileReq = fileName:sub(1, (-1 - luaSuffix:len()))
                    local fileRelPath = libHelper.formPath(v1, fileName)

                    if (gPrefix == (rootLen + 1)) then
                        table.insert(modFiles.globals, fileReq)
                    elseif (aPrefix == (rootLen + 1)) then
                        table.insert(modFiles.abils, fileReq)
                    elseif (uPrefix == (rootLen + 1)) then
                        table.insert(modFiles.units, fileReq)
                    elseif (fPrefix == (rootLen + 1)) then
                        tocBuffer = tocBuffer .. fileRelPath .. "\n"
                        table.insert(modFiles.imports, {fileRelPath})
                    end
                end
            end

            -- Tell Ceres to check module folder for library functions --
            table.insert(ceres.layout.srcDirectories, v1)

            -- Check for other module imports --
            if (fs.exists(libHelper.formPath(v1, "imports.lua"))) then
                local modImports = require(libHelper.formPath(v1, "imports"))
                if (type(modImports) == "table") then
                    for k, v in pairs(modImports) do
                        table.insert(modFiles.imports, v)
                    end
                end
            end

        else
            print("> ERROR: Module \"" .. v1 .. "\" doesn't exist!")
        end
    end

    -- Create one TOC file for all module FDFs --
    if (tocBuffer ~= "") then
        print("\n> NOTE: Module FDFs detected. Generating module TOC file...")
        local outputPath = libHelper.formPath(projDir, "target", "_build", "libFrames.toc")
        local try, msg = fs.writeFile(outputPath, tocBuffer)
        if (try == false) then
            print("> ERROR: Failed writing libFrames.toc" )
            print("    " .. msg)
        else
            table.insert(modFiles.imports, {outputPath, "libFrames.toc"})
            print("> SUCCESS: Generated libFrames.toc! ")
        end
    end

    return modFiles
end



--==================================================================--
-- parseSrcFrames()                                                 --
--                                                                  --
-- Detects all top-level FDF files in 'proj-dir/src/war3mod/fdfs/'. --
-- Generates a TOC file: 'proj-dir/target/_build/srcFrames.toc'     --
-- Returns a table with MPQ file imports (the FDFs and TOC).        --
-- See 'template/src/war3mod/fdfs/' for more info.                  --
--==================================================================--
libBuild.parseSrcFrames = function()
    local projDir = ceres.getScriptArgs()[1]
    local folderPath = libHelper.formPath(projDir, "src", "war3mod", "fdfs")
    local absFilePaths = libHelper.readDirFilesWithSuffix(folderPath, ".fdf")
    local imports = {}

    if ((type(absFilePaths) == "table") and (#absFilePaths > 0)) then
        print("> SUCCESS: Source FDFs detected. Generating source TOC file...")
        local tocBuffer = ""

        for k, v in pairs(absFilePaths) do
            local fileName = v:sub(libHelper.getLowestLevelStart(v))
            local filePathInsideMPQ = libHelper.formPath("fdfs", fileName)
            table.insert(imports, {v, filePathInsideMPQ})
            tocBuffer = tocBuffer .. filePathInsideMPQ .. "\n"
        end
        
        local outputPath = libHelper.formPath(projDir, "target", "_build", "srcFrames.toc")
        local try, msg = fs.writeFile(outputPath, tocBuffer)
        if (try == false) then
            print("> ERROR: Failed writing srcFrames.toc" )
            print("    " .. msg)
        else
            table.insert(imports, {outputPath, "srcFrames.toc"})
            print("> SUCCESS: Generated srcFrames.toc! ")
        end
    end
    
    return imports
end



--===================================================================--
-- generateRuntimeMain()                                             --
--   modGlobals: table[strings]                                      --
--   modAbils: table[strings]                                        --
--   modUnits: table[strings]                                        --
--   srcAbils: table[strings]                                        --
--   srcUnits: table[strings]                                        --
--   srcObjs: table[strings]                                         --
--   srcTrigs: table[strings]                                        --
--   srcMains: table[strings]                                        --
--                                                                   --
-- Generates a single file at "proj-dir/target/_build/mainInit.lua". --
-- It requires all runtime scripts used by this project.             --
--===================================================================--
libBuild.generateRuntimeMain = function(modGlobals, modAbils, modUnits, srcAbils, srcUnits, srcObjs, srcTrigs, srcMains)
    local projDir = ceres.getScriptArgs()[1]
    local firstHeader = false
    local newFileBuffer = ""

    local function addInitHeader(header, marginLeft, marginRight)
        header      = header or "    "
        marginLeft  = marginLeft or "-- "
        marginRight = marginRight or " --"
        local width = header:len() + marginLeft:len() + marginRight:len()

        local border = ""
        for i=1, width do
            border = border .. "-"
        end

        if (firstHeader == false) then
            firstHeader = true
        else
            newFileBuffer = newFileBuffer .. "\n\n"
        end

        newFileBuffer = newFileBuffer              .. "\n"
            ..               border                .. "\n"
            .. marginLeft .. header .. marginRight .. "\n"
            ..               border                .. "\n"
    end

    local function addInitSubheader(subheader)
        newFileBuffer = newFileBuffer      .. "\n"
            .. "-- " .. subheader .. " --" .. "\n"
    end

    local function addInitScripts(table)
        for k, v in pairs(table) do
            newFileBuffer = newFileBuffer .. "require \"" .. v .. "\"\n"
        end
    end

    addInitHeader("Init Modules")
        addInitSubheader("Init Globals")
        addInitScripts(modGlobals)

        addInitSubheader("Define Custom Abilities")
        addInitScripts(modAbils)

        addInitSubheader("Define Custom Units")
        addInitScripts(modUnits)

    addInitHeader("Init Source")
        addInitSubheader("Define Custom Abilities")
        addInitScripts(srcAbils)

        addInitSubheader("Define Custom Units")
        addInitScripts(srcUnits)

        addInitSubheader("Create Object Instances")
        addInitScripts(srcObjs)

        addInitSubheader("Create Initial Triggers")
        addInitScripts(srcTrigs)

        addInitSubheader("Main")
        addInitScripts(srcMains)

    local outputPath = libHelper.formPath(projDir, "target", "_build", "mainInit.lua")
    local try, msg = fs.writeFile(outputPath, newFileBuffer)
    if (try == false) then
        print("> ERROR: Failed writing mainInit.lua" )
        print(">   " .. msg)
    else
        print("> SUCCESS: Generated mainInit.lua! ")
    end
end



--===========================================================--
-- compileMaps()                                             --
--   maps: table[strings]                                    --
--   imports: table[]                                        --
--   args: table - (k) string - (v) true or nil              --
--                                                           --
-- Compiles all maps designated by this project's config.    --
-- Creates a DirMap, adds imports, then creates an MPQ file. --
-- Compiled maps are found in "proj-dir/target/".            --
--===========================================================--
libBuild.compileMaps = function(maps, imports, args)
    local pathSeparator = package.config:sub(1,1)
    local lastMap

    -- Compile each map --
    for i=1,(#maps) do
        print("\nCompiling " .. maps[i])

        -- Translate absolute monorepo map path to local folder path and local file path --
        local fileStart = libHelper.getLowestLevelStart(maps[i])
        local localMap

        if (fileStart ~= nil) then
            ceres.layout.mapsDirectory = maps[i]:sub(1, (fileStart - pathSeparator:len()))
            localMap = maps[i]:sub(fileStart)
        else
            ceres.layout.mapsDirectory = pathSeparator
            localMap = maps[i]
        end

        -- Remove existing build artifact using correct OS command --
        if (args.d == true) then
            local existingDir = ceres.layout.targetDirectory .. localMap .. ".dir"
            if (fs.exists(existingDir)) then
                print("> [d] Deleting existing DirMap \"" .. existingDir .. "\"")
                if (pathSeparator == "\\") then os.execute('rd /s/q "' .. existingDir .. '"')  -- Windows
                elseif (pathSeparator == "/") then os.execute('rm -rd "' ..existingDir .. '"') end  -- Unix
            end
        end

        -- Compile a directory map, add file imports, then create an MPQ map with the directory --
        local map = ceres.buildMap({input = localMap, output = "dir", retainMapScript = true})

        if (map ~= false) then
            print("> Copying imports to \"" .. localMap .. "\"")

            for k=1,(#imports) do
                local targetPath = map.path .. (imports[k][2] or imports[k][1])
                local try, msg = false, ""

                if (fs.isFile(imports[k][1])) then
                    try, msg = fs.copyFile(imports[k][1], targetPath)
                elseif (fs.isDir(imports[k][1])) then
                    try, msg = fs.copyDir(imports[k][1], targetPath)
                end
                
                if (try == false) then
                    print("> Error copying \"" .. imports[k][1] .. "\" to \"" .. targetPath .. "\"")
                    print(">   " .. msg)
                else
                    print("> Copied \"" .. imports[k][1] .. "\" to \"" .. targetPath .. "\"")
                end
            end
            
            print("> Creating new MPQ from compiled DirMap")
            local newMPQ = mpq.create()
            lastMap = map.path:sub(1, (#map.path - 5))
            newMPQ:addFromDir(map.path)
            newMPQ:write(lastMap)
        else
            print("> ERROR: Compiling DirMap for \"" .. maps[i] .. "\" failed.")
        end
    end

    -- Run last map successfully compiled --
    if (args.r == true) then
        if (lastMap ~= nil) then
            ceres.runMap(lastMap)
        else
            print("No map to run!")
        end
    end
end




--===========--
return libBuild
--===========--
