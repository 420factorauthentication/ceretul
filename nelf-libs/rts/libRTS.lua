--=============--
local libRTS = {}
--=============--

-- < References > --
local constRTS = require "constRTS"



--============================================================--
-- adjustStatReal()                                           --
--   playerId: int                                            --
--   statType: libRTS.statType                                --
--   statId: see comments on constRTS.statType                --
--   delta: real                                              --
--   spawnLocX: real (only used if statType is unitId)        --
--   spawnLocY: real (only used if statType is unitId)        --
--   spawnFace: real (only used if statType is unitId)        --
--                                                            --
-- Adds or subtracts a decimal amount of a War3 integer stat. --
-- The leftover decimal amount is tracked in a global var.    --
--============================================================--
libRTS.adjustPlayerStateReal = function(playerId, statType, statId, delta, spawnLocX, spawnLocY, spawnFace)
    if (gRTS.leftover[statId] == nil) then
        gRTS.leftover[statId] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    end

    gRTS.leftover[statId][playerId+1] = gRTS.leftover[statId][playerId+1] + delta
    if (gRTS.leftover[statId][playerId+1] >= 1) or (gRTS.leftover[statId][playerId+1] <= -1) then
        local intAmt = math.floor(gRTS.leftover[statId][playerId+1])
        gRTS.leftover[statId][playerId+1] = gRTS.leftover[statId][playerId+1] - intAmt

        if (statType == constRTS.statType.resource) then
            AdjustPlayerStateBJ(intAmt, Player(playerId), statId)
        elseif (statType == constRTS.statType.techId) then
            AddPlayerTechResearched(Player(playerId), FourCC(statId), intAmt)
        elseif (statType == constRTS.statType.unitId) then
            CreateUnit(Player(playerId), FourCC(statId), spawnLocX, spawnLocY, spawnFace)
        end
    end
end



--=========================================================--
-- getStatReal()                                           --
--   playerId: int                                         --
--   statType: libRTS.statType                             --
--   statId: see comments on constRTS.statType             --
--                                                         --
-- Get how much a player has, including decimal leftovers. --
--=========================================================--
libRTS.getStatReal = function(playerId, statType, statId)
    if (statType == constRTS.statType.resource) then
        return (GetPlayerState(Player(playerId), statId) + gRTS.leftover[statId][playerId+1])
    elseif (statType == constRTS.statType.techId) then
        return (GetPlayerTechCount(Player(playerId), FourCC(statId), true) + gRTS.leftover[statId][playerId+1])
    elseif (statType == constRTS.statType.unitId) then
        return (GetPlayerTypedUnitCount(Player(playerId), GetObjectName(FourCC(statId)), true, true) + gRTS.leftover[statId][playerId+1])
    end
end



--===============================================================--
-- class statInstance                                            --
-- A single instance of a stat (resource, tech, unit) and amount --
-- Used for handling object costs, requirements, and effects     --
--===============================================================--
libRTS.statInstance = setmetatable({
    Name = "New Resource Check",

    --== Settings ==--
    Delay    = 0,    -- Time before adjustments happen
    Duration = 0,    -- After an adjustment happens, time until effect is reversed. If <= 0, effect is permanent
    StatType,        -- constRTS.statType
    StatId,          -- see comments on constRTS.statType
    Delta,           -- real

    --== Settings: if StatType is unitId ==--
    SpawnLocX,  -- real
    SpawnLocY,  -- real
    SpawnFace,  -- real. Rotation in degrees.

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        setmetatable(o, {__index = self})
        return o
    end,

    --===================================================--
    -- statInst:adjust()                                 --
    --   playerId: int                                   --
    --   inverse: bool = false                           --
    --                                                   --
    -- Adds the delta to the player's current resources. --
    -- If inverse is true, subtracts it.                 --
    --===================================================--
    adjust = function(self, playerId, inverse)
        if (inverse == nil) then inverse = false end
        local amount = (inverse) and (-self.Delta) or (self.Delta) --ternary op

        if (self.Duration > 0) or (self.Delay > 0) then
            local trig = CreateTrigger()
            local action = function()
                TriggerSleepAction(self.Delay)    
                libRTS.adjustStatReal(playerId, self.StatType, self.StatId, amount, self.SpawnLocX, self.SpawnLocY, self.SpawnFace)

                if (self.Duration > 0) then
                    TriggerSleepAction(self.Duration)
                    libRTS.adjustStatReal(playerId, self.StatType, self.StatId, -amount, self.SpawnLocX, self.SpawnLocY, self.SpawnFace)
                end

                DestroyTrigger(trig)
            end

            TriggerAddAction(trig, action)
            TriggerExecute(trig)
        else
            libRTS.adjustStatReal(playerId, self.StatType, self.StatId, amount, self.SpawnLocX, self.SpawnLocY, self.SpawnFace)
        end
    end

    --======================================================--
    -- statInst:check()                                     --
    --   playerId: int                                      --
    --                                                      --
    -- Returns true if the player has at least this amount. --
    --======================================================--
    check = function(self, playerId)
        if (libRTS.getStatReal(playerId, self.StatType, self.StatId) >= self.Delta) then
            return true
        else
            return false
        end
    end
    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--=========--
return libRTS
--=========--
