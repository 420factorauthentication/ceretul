--=================--
local libUnitAtk = {}
--=================--

-- < Modules > --
local math2 = require "math2"
local table2 = require "table2"



--================================================================================--
-- class slash                                                                    --
--                                                                                --
-- An attack with a moving rectangular hitbox, damage, and VFX.                   --
--                                                                                --
-- If TimeLength <= 0 or Keyframes <= 1: Only hitbox start is used.               --
-- If TimeLength > 0 and Keyframes >= 2: Hitbox interpolates from start to end.   --
--                                                                                --
-- If a Target Filter table is empty, that filter type has no effect.             --
-- If not, the target unit must match the stored bool.                            --
--                                                                                --
-- Example:                                                                       --
-- If FilterAllyTypes is empty, allied and enemy units can be hit.                --
-- If FilterAllyTypes[alliancetype] == true, only allied units can be hit.        --
-- If FilterAllyTypes[alliancetype] == false, only enemy units can be hit.        --
--                                                                                --
-- Visual Effect tables accept strings (model filepath) or libVFX.vfxTemplate.    --
-- Use a string to create an Effect with default settings and better performance. --
--================================================================================--
libUnitAtk.slash = setmetatable({
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
    EndMinY,  -- In-game coordinate. Relative bottom edge of hitbox end
    EndMaxY,  -- In-game coordinate. Relative top edge of hitbox end  

    --== Target Filters ==--
    FilterUnitIds   = {},  -- k: string (Four-char unitid)   v: bool
    FilterUnitTypes = {},  -- k: (native) unittype           v: bool
    FilterAllyTypes = {},  -- k: (native) alliancetype       v: bool

    --== Visual Effects ==--
    OriginVFX = {},  -- v: string (model path) or libVFX.vfxTemplate. Created on attacking unit
    MotionVFX = {},  -- v: string (model path) or libVFX.vfxTemplate. Created on each hitbox frame
    TargetVFX = {},  -- v: string (model path) or libVFX.vfxTemplate. Created on units hit by attack
    
    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        
        -- Init default params and methods --
        o.FilterUnitIds   = o.FilterUnitIds   or {}
        o.FilterUnitTypes = o.FilterUnitTypes or {[UNIT_TYPE_DEAD] = false}
        o.FilterAllyTypes = o.FilterAllyTypes or {}

        o.OriginVFX = o.OriginVFX or {}
        o.MotionVFX = o.MotionVFX or {}
        o.TargetVFX = o.TargetVFX or {}
        
        setmetatable(o, {__index = self})

        if (o.TimeStart  < 0) then o.TimeStart  = 0 end
        if (o.TimeLength < 0) then o.TimeLength = 0 end
        if (o.Keyframes  < 1) then o.Keyframes  = 1 end

        -- Return --
        return o
    end,

    --=================================================--
    -- slash:launch()                                  --
    --   originUnit: (native) unithandle               --
    --                                                 --
    -- Checks hitboxes relative to originUnit.         --
    -- Damages units already inside hitboxes.          --
    -- Uses a trigger to damage units on hitbox enter. --
    --=================================================--
    launch = function(self, originUnit)
        local hitCounts = {}  -- MaxHits counter
        local frameLength = self.TimeLength / self.Keyframes

        -- GroupEnum and EnterRegion filter: Only hit specified units --
        local filter = Filter(function()
            local next = next  --compiler optimization
            local targetUnit = GetFilterUnit()

            if (targetUnit == originUnit) then return false end
            if (BlzIsUnitInvulnerable(targetUnit)) then return false end

            if (next(self.FilterUnitIds) ~= nil)  --if table not empty
            and (self.FilterUnitIds[GetUnitTypeId(targetUnit)] ~= true) then
                return false
            end

            if (next(self.FilterUnitTypes) ~= nil) then  --if table not empty
                for k, v in pairs(self.FilterUnitTypes) do
                    if (IsUnitType(targetUnit, k) ~= v) then return false end
                end
            end
            
            if (next(self.FilterAllyTypes) ~= nil) then  --if table not empty
                local sourcePlayer = GetOwningPlayer(originUnit)
                local otherPlayer  = GetOwningPlayer(targetUnit)
                for k, v in pairs(self.FilterAllyTypes) do
                    if (GetPlayerAlliance(sourcePlayer, otherPlayer, k) ~= v) then return false end
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

            -- TargetVFX: Lasts for duration of one keyframe --
            local activeTargetVFX = {}

            for k, v in pairs(self.TargetVFX) do
                -- String (model path): Effect with default settings --
                if (type(v) == "string") then
                    table.insert(activeTargetVFX,
                        AddSpecialEffect(v, GetUnitX(targetUnit), GetUnitY(targetUnit)))
                
                else -- libVFX.vfxTemplate: Effect with custom settings --
                    table.insert(activeTargetVFX,
                        v:create(GetUnitX(targetUnit), GetUnitY(targetUnit)), BlzGetLocalUnitZ(targetUnit))
                end
            end

            -- Cleanup TargetVFX --
            if (#activeTargetVFX > 0) then
                local trigCleanupTargetVFX = CreateTrigger()
                TriggerAddAction(trigCleanupTargetVFX, function()
                    for k, v in pairs(activeTargetVFX) do
                        DestroyEffect(v)
                        activeTargetVFX[k] = nil
                    end DestroyTrigger(trigCleanupTargetVFX)
                end) TriggerRegisterTimerEventSingle(trigCleanupTargetVFX, frameLength)
            end
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

            -- MotionVFX: Lasts for duration of one keyframe --
            local activeMotionVFX = {}
            local centerX = (maxX + minX) / 2
            local centerY = (maxY + minY) / 2

            for k, v in pairs(self.MotionVFX) do
                -- String (model path): Effect with default settings --
                if (type(v) == "string") then
                    table.insert(activeMotionVFX, AddSpecialEffect(v, centerX, centerY))
                
                else -- libVFX.vfxTemplate: Effect with custom settings --
                    table.insert(activeMotionVFX, v:create(centerX, centerY))
                end
            end

            -- Cleanup hitbox and MotionVFX --
            local hitboxCleanupTrig = CreateTrigger()
            TriggerAddAction(hitboxCleanupTrig, function()
                for k, v in pairs(activeMotionVFX) do
                    DestroyEffect(v)
                    activeMotionVFX[k] = nil
                end

                DestroyTrigger(trigger)
                RemoveRegion(region)
                RemoveRect(rect)
                DestroyTrigger(hitboxCleanupTrig)
            end) TriggerRegisterTimerEventSingle(hitboxCleanupTrig, duration)
        end

        -- Run hitbox start once --
        local originUnitX = GetUnitX(originUnit)
        local originUnitY = GetUnitY(originUnit)
        local hitboxMinX = originUnitX + self.StartMinX
        local hitboxMaxX = originUnitX + self.StartMaxX
        local hitboxMinY = originUnitY + self.StartMinY
        local hitboxMaxY = originUnitY + self.StartMaxY
        runTimedHitbox(frameLength, hitboxMinX, hitboxMaxX, hitboxMinY, hitboxMaxY)

        -- If attack has a duration --
        local hitboxTrig
        local keyframesElapsed = 1
        if (self.TimeLength > 0) then 

            -- OriginVFX: Lasts for duration of attack --
            local activeOriginVFX = {}

            for k, v in pairs(self.OriginVFX) do
                -- String (model path): Effect with default settings --
                if (type(v) == "string") then
                    table.insert(activeOriginVFX,
                        AddSpecialEffect(v, GetUnitX(originUnit), GetUnitY(originUnit)))
                
                else -- libVFX.vfxTemplate: Effect with custom settings --
                    table.insert(activeOriginVFX,
                        v:create(GetUnitX(originUnit), GetUnitY(originUnit)), BlzGetLocalUnitZ(originUnit))
                end
            end

            -- Cleanup OriginVFX --
            if (#activeOriginVFX > 0) then
                local trigCleanupOriginVFX = CreateTrigger()
                TriggerAddAction(trigCleanupOriginVFX, function()
                    for k, v in pairs(activeOriginVFX) do
                        DestroyEffect(v)
                        activeOriginVFX[k] = nil
                    end DestroyTrigger(trigCleanupOriginVFX)
                end) TriggerRegisterTimerEventSingle(trigCleanupOriginVFX, self.TimeLength)
            end
        
            -- Hitbox interpolation --
            if (self.Keyframes >= 2) then
                local deltaMinX = (self.EndMinX - self.StartMinX) / (self.Keyframes - 1)
                local deltaMaxX = (self.EndMaxX - self.StartMaxX) / (self.Keyframes - 1)
                local deltaMinY = (self.EndMinY - self.StartMinY) / (self.Keyframes - 1)
                local deltaMaxY = (self.EndMaxY - self.StartMaxY) / (self.Keyframes - 1)

                hitboxTrig = CreateTrigger()
                TriggerAddAction(hitboxTrig, function()
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
                end) TriggerRegisterTimerEventPeriodic(hitboxTrig, frameLength)
            end
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
