--============--
local math2 = {}
--============--

-- < Modules > --
local helper = require "helper"



--===================================================================--
-- convToGrid()                                                      --
--   distUnits: number                                               --
--                                                                   --
-- Converts in-game Distance Units/Pixels to WorldEditor Grid Units. --
-- 128 Distance Units = 1 WorldEditor Grid Unit                      --
--===================================================================--
math2.convToGrid = function(distUnits)
    distUnits = assert(tonumber(distUnits), "ERROR convToGrid: invalid input")
    return distUnits / 128
end



--====================================================================--
-- convToDist()                                                       --
--   gridUnits: number                                                --
--   returns: number                                                  --
--                                                                    --
-- Converts World Editor Grid Units to in-game Distance Units/Pixels. --
-- 128 Distance Units = 1 WorldEditor Grid Unit                       --
--====================================================================--
math2.convToDist = function(gridUnits)
    gridUnits = assert(tonumber(gridUnits), "ERROR convToDist: invalid input")
    return gridUnits * 128
end



--===================================================--
-- convScales()                                      --
--   input: real                                     --
--   inputScaleMin: real                             --
--   inputScaleMax: real                             --
--   outputScaleMin: real                            --
--   outputScaleMax: real                            --
--                                                   --
-- Converts a number within one min/max set          --
-- to its equivalent in another min/max set.         --
-- Example: In the range of (-1 to 1), 0.5 is 75%    --
-- converting this to 75% of the range of (0 to 255) --
-- would be 191.25                                   --
--===================================================--
math2.convScales = function(input, inputScaleMin, inputScaleMax, outputScaleMin, outputScaleMax)
    return (((input - inputScaleMin) / (inputScaleMax - inputScaleMin)) * (outputScaleMax - outputScaleMin) + outputScaleMin)
end



--=====================================--
-- clamp()                             --
--   input: real                       --
--   bound1: real                      --
--   bound2: real                      --
--                                     --
-- Clamps a number between two bounds. --
--=====================================--
math2.clamp = function(input, bound1, bound2)
    local low = math.min(bound1, bound2)
    local high = math.max(bound1, bound2)

    if (input < low) then
        return low
    elseif (input > high) then
        return high
    else
        return input
    end
end



--==================================================--
-- class vec3                                       --
-- A container for a 3D vector and related methods. --
--==================================================--
math2.vec3 = setmetatable({
    x = 0,
    y = 0,
    z = 0,

    --===============--
    -- Constructor   --
    --   x: real = 0 --
    --   y: real = 0 --
    --   z: real = 0 --
    --===============--
    new = function(self, x, y, z)
        x = x or 0
        y = y or 0
        z = z or 0
        o = {}
        setmetatable(o, {__index = self})
        o.x = assert(tonumber(x), "ERROR vec3:new(): invalid x input")
        o.y = assert(tonumber(y), "ERROR vec3:new(): invalid y input")
        o.z = assert(tonumber(z), "ERROR vec3:new(): invalid z input")
        
        return o
    end,

    --=================================================================--
    -- vec3:cross()                                                    --
    --   v2: vec3                                                      --
    --                                                                 --
    -- Calculates the cross product of this vector and another vector. --
    --=================================================================--
    cross = function(self, v2, out)
        out = out or self
        out.x = self.y * v2.z - self.z * v2.y
        out.y = self.z * v2.x - self.x * v2.z
        out.z = self.x * v2.y - self.y * v2.x
        return out
    end,

    --===============================================================--
    -- vec3:dot()                                                    --
    --   v2: vec3                                                    --
    --                                                               --
    -- Calculates the dot product of this vector and another vector. --
    --===============================================================--
    dot = function(self, v2)
        return self.x * v2.x + self.y * v2.y + self.z * v2.z
    end,

    --==========================================--
    -- vec3:length()                            --
    --                                          --
    -- Calculates the magnitude of this vector. --
    --==========================================--
    length = function(self)
        return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
    end,

    --================================================--
    -- vec3:normalize()                               --
    --                                                --
    -- Modifies this vector to have a magnitude of 1. --
    --================================================--
    normalize = function(self)
        local length = self:length()
        if (length ~= 0) then
            self.x = self.x / length
            self.y = self.y / length
            self.z = self.z / length
        end
    end,

    --==================================================================--
    -- vec3:normalized()                                                --
    --                                                                  --
    -- Returns a new vector with the same direction and magnitude of 1. --
    --==================================================================--
    normalized = function(self)
        local length = self:length()
        local new = {}
        local newMeta = {}
        setmetatable(new, newMeta)

        -- Preserve other added properties --
        for k, v in pairs(self) do
            new[k] = v end
        for k, v in pairs(getmetatable(self)) do
            newMeta[k] = v end

        -- Stop the universe from imploding from dividing by 0 --
        if (length ~= 0) then
            new.x = self.x / length
            new.y = self.y / length
            new.z = self.z / length
        end

        return new
    end,

    --=========================================--
    -- vec3:pitch()                            --
    --                                         --
    -- Calculates rotation about the XZ plane. --
    -- Returns degrees.                        --
    --=========================================--
    pitch = function(self)
        --return math.deg(math.atan(self.y, math.sqrt(self.x*self.x + self.z*self.z))) - 90
        if (helper.equalsZeroEpsilon(self.x, 0.0001)) then
            if (helper.equalsZeroEpsilon(self.y, 0.0001)) then
                if (self.z >= 0) then
                    return 90
                else
                    return -90
                end
            else
                return math.deg(math.atan(self.z, self.y))
            end
        else
            return math.deg(math.atan(self.z, self.x))
        end
    end,

    --=========================================--
    -- vec3:yaw()                              --
    --                                         --
    -- Calculates rotation about the XY plane. --
    -- Returns degrees.                        --
    --=========================================--
    yaw = function(self)
        return math.deg(math.atan(self.y, self.x))
    end
    },{

    --===========--
    -- Metatable --
    --===========--
    
})



--========--
return math2
--========--
