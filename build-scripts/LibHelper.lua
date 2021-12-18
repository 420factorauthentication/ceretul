--================--
local libHelper = {}
--================--



--===================================================================--
-- getLowestLevelStart()                                             --
--   path: string                                                    --
--   delim: string = (OS Path Separator)                             --
--   countAllSlashes: boolean = true                                 --
--                                                                   --
-- In a string, finds the index of the last path separator (/ or \). --
-- Returns (index + 1) if successful.                                --
-- Returns nil if unsuccessful.                                      --
--===================================================================--
libHelper.getLowestLevelStart = function(path)
    local i, j = 0, 0
    local i2, j2
    local delimFoundCount = -1
    local delimPattern

    repeat
        i2, j2 = i, j
        i, j = path:find("[/\\]", (j + 1))
        delimFoundCount = delimFoundCount + 1
    until (i == nil)

    if (delimFoundCount > 0) then
        return (j2 + 1)
    end
end



--============================================================--
-- formPath()                                                 --
--   ...  : strings                                           --
--                                                            --
-- Inserts path separators between strings, forming one path. --
--============================================================--
libHelper.formPath = function(...)
    local pathSeparator = package.config:sub(1,1) or "/"
    local first = true
    local output = ""

    for i=1, select("#", ...) do
        if (first == false) then
            output = output .. pathSeparator
        else
            first = false
        end
        local nextString = select(i, ...)
        output = output .. nextString
    end

    return output
end



--=========================================--
-- parseOutputScript()                     --
--   path: string                          --
--                                         --
-- Checks if a Lua file exists.            --
-- If it does, tries to return its output. --
--=========================================--
libHelper.parseOutputScript = function(path)
    if (fs.exists(path)) then
        local suffix = ".lua"
        local output = require (path:sub(1, (-1 - suffix:len())))
        return output
    end
end



--=================================================================================--
-- getFolderFilesNoEndings()                                                       --
--   path: string                                                                  --
--   onlyEnding: string = nil                                                      --
--                                                                                 --
-- *DEPRECATED*                                                                    --
-- Detects all files in a folder.                                                  --
-- Returns a table of filenames without extension endings (ex: '.lua').            --
-- If onlyEnding is provided, only includes files that originally had that ending. --
-- Include a period in onlyEnding (ex: '.lua').                                    --
--=================================================================================--
libHelper.getFolderFilesNoEndings = function(path, onlyEnding)
    local output = {}
    local pathSeparator = package.config:sub(1,1)
    local fileNameStart = fs.absolutize(path):len() + pathSeparator:len() + 1
    local files = fs.readDir(path)

    if (type(files) == "table") then 
        for k, v in pairs(files) do
            local fileEnding = ""
            local fileEndingStart = libHelper.getLowestLevelStart(v, '.')
            if (fileEndingStart ~= nil) then
                fileEndingStart = fileEndingStart - 1    -- Includes the period
                fileEnding = v:sub(fileEndingStart)
            end

            if (onlyEnding ~= nil) then
                if (fileEnding:lower() == onlyEnding:lower()) then
                    table.insert(output, v:sub(fileNameStart, (-1 - fileEnding:len())))
                end
            else
                table.insert(output, v:sub(fileNameStart, (-1 - fileEnding:len())))
            end
        end
    end
    
    return output
end



--=====================================================================================--
-- readDirFilesWithSuffix()                                                            --
--   path: string                                                                      --
--   suffix: string                                                                    --
--   includeSuffix: boolean = true                                                     --
--                                                                                     --
-- Tries to detect all files at the specified directory.                               --
-- Returns a table of absolute filepaths that end with the given suffix if successful. --
-- Returns false and an error if failed.                                               --
-- If includeSuffix is false, trims suffixes from output filepaths.                    --
-- NOTE: case-sensitive                                                                --
--=====================================================================================--
libHelper.readDirFilesWithSuffix = function(path, suffix, includeSuffix)
    includeSuffix = includeSuffix or true
    local try, msg = fs.readDir(path)
    if (type(try) == "table") then
        local output = {}
        for k, v in pairs(try) do
            local compare = v:sub(1 + v:len() - suffix:len())
            if (compare == suffix) then
                if (includeSuffix == false) then
                    table.insert(output, v:sub(1, (-1 - suffix:len())))
                else
                    table.insert(output, v)
                end
            end
        end
        return output
    end
    return try, msg
end



--============================================================================--
-- writeStringTable()                                                         --
--   strings: table[string]                                                   --
--   outputPath: string                                                       --
--                                                                            --
-- Writes a file that contains all strings in a table, separated by newlines. --
-- Returns nothing if successful, and false and an error if failed.           --
--============================================================================--
libHelper.writeStringTable = function(strings, outputPath)
    local writeBuffer = ""
    for k, v in pairs(strings) do
        if (type(v) == "string") then
            writeBuffer = writeBuffer .. v .. "\n"
        end
    end
    return fs.writeFile(outputPath, writeBuffer)
end



--============--
return libHelper
--============--
