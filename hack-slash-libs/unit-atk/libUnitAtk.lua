--=================--
local libUnitAtk = {}
--=================--

-- < Modules > --
local math2 = require "math2"
local table2 = require "table2"



--==============================================================================--
-- class attack                                                                 --
--                                                                              --
-- One stage of a combo.                                                        --
-- Handles a moving hitbox, damage, and VFX.                                    --
--                                                                              --
-- If TimeLength <= 0 or Keyframes <= 1: Only hitbox start is used.             --
-- If TimeLength > 0 and Keyframes >= 2: Hitbox interpolates from start to end. --
--                                                                              --
-- If FilterUnitIds is empty, any unit type can be hit.                         --
-- If not empty, FilterUnitIds[unitId] must equal true.                         --
--                                                                              --
-- If FilterAllyTypes is empty, allied and enemy units can be hit.              --
-- If FilterAllyTypes[alliancetype] == true, only allied units can be hit.      --
-- If FilterAllyTypes[alliancetype] == false, only enemy units can be hit.      --
--==============================================================================--
libUnitAtk.attack = setmetatable({
    Name = "New Attack Moment",

    --== Damage Numbers ==--
    DmgFlatAmount   = 0,  -- real. Flat damage
    DmgMaxHpFactor  = 0,  -- real. Percent of Max HP of target (1 = 100% max hp)
    DmgCurrHpFactor = 0,  -- real. Percent of Current HP of target (1 = 100% curr hp)
    MaxHits         = 1,  -- int. Number of times each unit can be hit, across all hitboxes.

    --== Damage Flags ==--
    IsPhysical = true,   -- Unit attack flag. If false, ignores armor
    IsRanged   = false,  -- Not sure what this flag does

    AttackType = ATTACK_TYPE_NORMAL,    -- (native) attacktype
    DamageType = DAMAGE_TYPE_NORMAL,    -- (native) damagetype
    WeaponType = WEAPON_TYPE_WHOKNOWS,  -- (native) weapontype

    --== Hitbox ==--
    TimeStart  = 0,    -- real (seconds). Offset this attack from start of combo
    TimeLength = 0.1,  -- real (seconds). How long to go from first keyframe to last
    Keyframes  = 1,    -- Number of hitbox interpolation steps

    StartMinX,  -- In-game coordinate. Relative left edge of hitbox start
    StartMaxX,  -- In-game coordinate. Relative right edge of hitbox start
    StartMinY,  -- In-game coordinate. Relative bottom edge of hitbox start
    StartMaxY,  -- In-game coordinate. Relative top edge of hitbox start

    EndMinX,  -- In-game coordinate. Relative left edge of hitbox end
    EndMaxX,  -- In-game coordinate. Relative right edge of hitbox end
    EndMinY,  -- In-game hcoordinate. Relative bottom edge of hitbox end
    EndMaxY,  -- In-game coordinate. Relative top edge of hitbox end  

    --== Target Filters ==--
    FilterUnitIds   = {},  -- k: string (Four-char unitid)   v: bool
    FilterAllyTypes = {},  -- k: alliancetype (native)       v: bool

    --== Art ==--
    MotionVFX = {},  -- v: Path to model file. Created on each hitbox frame
    OriginVFX = {},  -- v: Path to model file. Created on attacking unit
    TargetVFX = {},  -- v: Path to model file. Created on units hit by attack
    
    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        
        -- Init empty table properties --
        o.FilterUnitIds   = o.FilterUnitIds   or {}
        o.FilterAllyTypes = o.FilterAllyTypes or {}

        o.MotionVFX = o.MotionVFX or {}
        o.OriginVFX = o.OriginVFX or {}
        o.TargetVFX = o.TargetVFX or {}

        -- Init default params and methods --
        setmetatable(o, {__index = self})

        -- Return --
        return o
    end,

    --=================================================--
    -- attack:launch()                                 --
    --   originUnit: (native) unithandle               --
    --                                                 --
    -- Checks hitboxes relative to originUnit.         --
    -- Damages units already inside hitboxes.          --
    -- Uses a trigger to damage units on hitbox enter. --
    --=================================================--
    launch = function(self, originUnit)
        local hitCounts = {}  -- MaxHits counter

        -- GroupEnum and EnterRegion filter: Only hit specified units --
        local filter = Filter(function()
            local targetUnit = GetFilterUnit()
            if (targetUnit == originUnit) then return false end
            if (BlzIsUnitInvulnerable(targetUnit)) then return false end

            if (#self.FilterUnitIds > 0)
            and (self.FilterUnitIds[GetUnitTypeId(targetUnit)] ~= true) then
                return false
            end
            
            if (#self.FilterAllyTypes > 0) then
                local sourcePlayer = GetOwningPlayer(originUnit)
                local otherPlayer  = GetOwningPlayer(targetUnit)
                for k, v in pairs(self.FilterAllyTypes) do
                    if (GetPlayerAlliance(sourcePlayer, otherPlayer, k) ~= v) then
                        return false
                    end
                end
            end

            return true
        end)

        -- Helper function: Damage one unit --
        local damageUnit = function(targetUnit)
            -- Track MaxHits --
            if (hitCounts[targetUnit] == nil) then hitCounts[targetUnit] = 0
            elseif (hitCounts[targetUnit] >= self.MaxHits) then return end

            -- Damage --
            local dmgMaxHp  = self.DmgMaxHpFactor * GetUnitState(targetUnit, UNIT_STATE_MAX_LIFE)
            local dmgCurrHp = self.DmgCurrHpFactor * GetUnitState(targetUnit, UNIT_STATE_LIFE)
            local dmgTotal  = self.DmgFlatAmount + dmgMaxHp + dmgCurrHp
            UnitDamageTarget(originUnit, targetUnit, dmgTotal,
                self.IsPhysical, self.IsRanged, self.AttackType, self.DamageType, self.WeaponType)

            -- VFX --
            
        end

        -- Helper function: One interpolation step of hitbox --
        local runTimedHitbox = function(duration, minX, maxX, minY, maxY)
            local rect = Rect(minX, minY, maxX, maxY)

            -- Damage units already inside --
            local group = CreateGroup()
            GroupEnumUnitsInRect(group, rect, filter)
            ForGroup(group, function() damageUnit(GetEnumUnit()) end)
            DestroyGroup(group) --Cleanup
    
            -- Create trigger to damage units on enter --
            local trigger = CreateTrigger()
            local region = CreateRegion()
            RegionAddRect(region, rect)
            TriggerRegisterEnterRegion(trigger, region, filter)
            TriggerAddAction(trigger, function() damageUnit(GetEnteringUnit()) end)

            -- Cleanup just this hitbox --
            local hitboxCleanupTrig = CreateTrigger()
            TriggerAddAction(hitboxCleanupTrig, function()
                DestroyTrigger(trigger)
                RemoveRegion(region)
                RemoveRect(rect)
                DestroyTrigger(hitboxCleanupTrig)
            end)
            TriggerRegisterTimerEventSingle(hitboxCleanupTrig, duration)
        end

        -- Run hitbox start once --
        local frameLength = self.TimeLength / self.Keyframes
        local originUnitX = GetUnitX(originUnit)
        local originUnitY = GetUnitY(originUnit)
        local hitboxMinX = originUnitX + self.StartMinX
        local hitboxMaxX = originUnitX + self.StartMaxX
        local hitboxMinY = originUnitY + self.StartMinY
        local hitboxMaxY = originUnitY + self.StartMaxY
        runTimedHitbox(frameLength, hitboxMinX, hitboxMaxX, hitboxMinY, hitboxMaxY)

        -- Hitbox interpolation --
        local hitboxTrig
        local keyframesElapsed = 1
        if (self.TimeLength > 0) and (self.Keyframes >= 2) then
            local deltaMinX = (self.EndMinX - self.StartMinX) / (self.Keyframes - 1)
            local deltaMaxX = (self.EndMaxX - self.StartMaxX) / (self.Keyframes - 1)
            local deltaMinY = (self.EndMinY - self.StartMinY) / (self.Keyframes - 1)
            local deltaMaxY = (self.EndMaxY - self.StartMaxY) / (self.Keyframes - 1)

            hitboxTrig = CreateTrigger()
            TriggerAddAction(hitboxTrig, function()
                print(frameLength)
                hitboxMinX = hitboxMinX + deltaMinX
                hitboxMaxX = hitboxMaxX + deltaMaxX
                hitboxMinY = hitboxMinY + deltaMinY
                hitboxMaxY = hitboxMaxY + deltaMaxY
                runTimedHitbox(frameLength, hitboxMinX, hitboxMaxX, hitboxMinY, hitboxMaxY)

                -- Cleanup everything else --
                keyframesElapsed = keyframesElapsed + 1
                if (keyframesElapsed >= self.Keyframes) then
                    DestroyFilter(filter)
                    for k, v in pairs(hitCounts) do hitCounts[k] = nil end
                    DestroyTrigger(hitboxTrig)
                end
            end)
            TriggerRegisterTimerEventPeriodic(hitboxTrig, frameLength)
        end
    end,
    },{

    --===========--
    -- Metatable --
    --===========--

})



--======================================--
-- class combo                          --
--                                      --
-- A chain of attacks, played in order. --
--======================================--
libUnitAtk.combo = setmetatable({
    Name = "New Attack Combo",

    --== Auto-Update Functionality On Change ==--
    Attacks = {},  -- attack class objects

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
    end,

    },{

    --===========--
    -- Metatable --
    --===========--

})



--=============--
return libUnitAtk
--=============--
