--=============--
local helper = {}
--=============--



--=========================================================================--
-- getProperty()                                                           --
--   property: table[any] | any                                            --
--   index: int                                                            --
--   default: any = nil                                                    --
--                                                                         --
-- Checks if a property is a table or a single value.                      --
-- If property is a table, returns the value at index of table.            --
-- If property is a single value, returns that single value.               --
-- If property is nil or index is out of bounds, returns default or nil.   --
--                                                                         --
-- Useful for classes that accept single values or tables as properties.   --
-- Example: libCam and libUnit can accept a single value for all players,  --
--   or a table that indexes by playerId                                   --
--=========================================================================--
helper.getProperty = function(property, index, default)
    if (property == nil) then
        return default
    elseif (type(property) == "table") then
        if (index ~= nil) then
            if (property[index] ~= nil) then
                return property[index]
            else
                return default
            end
        else
            if (property[1] ~= nil) then
                return property[1]
            else
                return default
            end
        end
    else
        return property
    end
end



--=============================================--
-- gsplit()                                    --
--   input: string                             --
--   delimiter: string (lua pattern)           --
--                                             --
-- Splits a string delimited by a lua pattern. --
-- Returns a table.                            --
--=============================================--
helper.gsplit = function(input, delimiter)
    input = assert(tostring(input), "ERROR gsplit: invalid input")
    delimiter = tostring(delimiter) or ","
    local output = {}
    local inputBuffer = input
    while (inputBuffer:len() > 0) do
        local delimiterPos = inputBuffer:find(delimiter)
        if (delimiterPos == nil) then
            table.insert(output, inputBuffer)
            break
        end
        local substring = inputBuffer:sub(1, delimiterPos-1)
        inputBuffer = inputBuffer:sub(delimiterPos+1)
        table.insert(output, substring)
    end
    return output
end



--===========================================================--
-- concatWithDelimiter()                                     --
--   strings: table[string]                                  --
--   delimiter: string                                       --
--                                                           --
-- Forms one string by concatenating all strings in a table, --
-- separating them with a delimiter.                         --
-- The table must be sorted by numerical indexes,            --
-- with no blank values inbetween.                           --
--===========================================================--
helper.concatWithDelimiter = function(strings, delimiter)
    if (type(strings) ~= "table") then
        local output = assert(tostring(strings), "ERROR concatWithDelimiter: invalid input")
        return output
    elseif (#strings <= 0) then
        return ""
    end

    delimiter = tostring(delimiter) or ","
    local output = ""
    
    for i=1,(#strings) do
        output = output .. strings[i] .. delimiter
    end

    output = string.sub(output, 1, string.len(output) - string.len(delimiter))
    return output
end



--================================================================--
-- equalsZeroEpsilon()                                            --
--   num: number                                                  --
--   epsilon: number                                              --
--                                                                --
-- Checks if a number is within the range (-epsilon to +epsilon). --
--================================================================--
helper.equalsZeroEpsilon = function(num, epsilon)
    num = assert(tonumber(num), "ERROR equalsZeroEpsilon: invalid input")
    epsilon = assert(tonumber(epsilon), "ERROR equalsZeroEpsilon: invalid epsilon")
    return ((num > -epsilon) and (num < epsilon))
end



--=========--
return helper
--=========--
