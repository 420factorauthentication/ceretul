--=============--
local libCam = {}
--=============--

-- < Modules > --
local libTrig = require "libTrig"
local table2  = require "table2"
local math2   = require "math2"
local helper  = require "helper"

-- < References > --
local constTrig = require "constTrig"



--===============================================================--
-- toggleFog()                                                   --
--                                                               --
-- If Fog is enabled, disable it. If Fog is disabled, enable it. --
--===============================================================--
libCam.toggleFog = function()
    if IsFogEnabled() then
        FogEnable(false)
    else
        FogEnable(true)
    end
end



--========================================================================--
-- toggleFogMask()                                                        --
--                                                                        --
-- If FogMask is enabled, disabled it. If FogMask is disabled, enable it. --
--========================================================================--
libCam.toggleFogMask = function()
    if IsFogMaskEnabled() then
        FogMaskEnable(false)
    else
        FogMaskEnable(true)
    end
end



--=====================================================================================--
-- lockCam()                                                                           --
--   playerId: int                                                                     --
--   allowLookAround: bool                                                             --
--                                                                                     --
-- If allowLookAround is false, prevents camera movement for a player.                 --
-- If allowLookAround is true, trying to move the camera rotates it instead.           --
-- To do so, creates a ghost unit at current CameraTargetPosition and locks cam to it. --
-- Preserves the current camView and orientation.                                      --
--=====================================================================================--
libCam.lockCam = function(playerId, allowLookAround)
    -- Sync CameraTargetPosition --
    local done = false
    local trigSync = CreateTrigger()
    libTrig.registerSyncEventForPlayingPlayers(trigSync, "lockCam")
    TriggerAddAction(trigSync, function()
        local data = helper.gsplit(BlzGetTriggerSyncData())
        local x = data[1]
        local y = data[2]
        local z = data[3]

        -- Create a dummy unit to lock the camera center on --
        local ghostTarget = CreateUnit(Player(27), FourCC('x000'), x, y, 0)
        SetUnitFlyHeight(ghostTarget, z, 1)
        if (GetLocalPlayer() == Player(playerId)) then
            SetCameraOrientController(ghostTarget, 0, 0)
        end

        -- Cleanup existing dummy unit --
        if (gCam.currCamGhostUnit[playerId+1] ~= nil) then
            RemoveUnit(gCam.currCamGhostUnit[playerId+1])
            gCam.currCamGhostUnit[playerId+1] = nil
        end

        -- Engine quirk: If locked unit is removed, scrolling the camera controls rotation instead --
        if (allowLookAround == true) then
            RemoveUnit(ghostTarget)
        else
            gCam.currCamGhostUnit[playerId+1] = ghostTarget
        end

        -- Signal trigger cleanup --
        done = true
    end)

    -- Send events to sync data and lock cam --
    if (GetLocalPlayer() == Player(playerId)) then
        local data = {}
        data[1] = GetCameraTargetPositionX()
        data[2] = GetCameraTargetPositionY()
        data[3] = GetCameraTargetPositionZ()
        local prefix = "lockCam" .. "," .. playerId
        local packet = helper.concatWithDelimiter(data)
        BlzSendSyncData(prefix, packet)
    end

    -- Clean up data sync trigger --
    local trigCleanup = CreateTrigger()
    TriggerAddAction(trigCleanup, function()
        while (done == false) do
            TriggerSleepAction(0.01)
        end
        DestroyTrigger(trigSync)
        DestroyTrigger(trigCleanup)
    end)
    TriggerExecute(trigCleanup)
end



--========================================================================--
-- unlockCam()                                                            --
--   playerId: int                                                        --
--                                                                        --
-- Re-enables camera movement for a player and turns off allowLookAround. --
-- Preserves the current camView, except camera roll.                     --
--========================================================================--
libCam.unlockCam = function(playerId)
    if (GetLocalPlayer() == Player(playerId)) then
        local offsetZ    = GetCameraField(CAMERA_FIELD_ZOFFSET)
        local localPitch = math.deg(GetCameraField(CAMERA_FIELD_LOCAL_PITCH))
        local localRoll  = math.deg(GetCameraField(CAMERA_FIELD_LOCAL_ROLL))
        local localYaw   = math.deg(GetCameraField(CAMERA_FIELD_LOCAL_YAW))
        local fov        = math.deg(GetCameraField(CAMERA_FIELD_FIELD_OF_VIEW))
        local nearZ      = GetCameraField(CAMERA_FIELD_NEARZ)
        local farZ       = GetCameraField(CAMERA_FIELD_FARZ)

        -- CameraFields dont update during allowLookAround --
        -- So calculate them from vectors --
        local camX    = GetCameraEyePositionX()
        local camY    = GetCameraEyePositionY()
        local camZ    = GetCameraEyePositionZ()
        local targetX = GetCameraTargetPositionX()
        local targetY = GetCameraTargetPositionY()
        local targetZ = GetCameraTargetPositionZ()
        local target  = math2.vec3:new(targetX - camX, targetY - camY, targetZ - camZ)
        local angleOfAtk = target:altitude()
        local rotation   = target:azimuth()
        local targetDist = target:length()
        local roll       = math.deg(GetCameraField(CAMERA_FIELD_ROLL)) --todo: calculate roll (is it possible?)
        
        -- Unlock camera and reset allowLookAround --
        SetCameraOrientController(gCam.camGhostUnitReset, 0, 0)
        ResetToGameCamera(0)

        -- Restore camView and orientation --
        SetCameraField(CAMERA_FIELD_ZOFFSET, offsetZ, 0)
        SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, targetDist, 0)
        SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, angleOfAtk, 0)
        SetCameraField(CAMERA_FIELD_ROLL, roll, 0)
        SetCameraField(CAMERA_FIELD_ROTATION, rotation, 0)
        SetCameraField(CAMERA_FIELD_LOCAL_PITCH, localPitch, 0)
        SetCameraField(CAMERA_FIELD_LOCAL_ROLL, localRoll, 0)
        SetCameraField(CAMERA_FIELD_LOCAL_YAW, localYaw, 0)
        SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, fov, 0)
        SetCameraField(CAMERA_FIELD_NEARZ, nearZ, 0)
        SetCameraField(CAMERA_FIELD_FARZ, farZ, 0)
    end 

    -- Cleanup previous dummy unit --
    if (gCam.currCamGhostUnit[playerId+1] ~= nil) then
        RemoveUnit(gCam.currCamGhostUnit[playerId+1])
        gCam.currCamGhostUnit[playerId+1] = nil
    end
end



--==========================================================================--
-- unlockCamSimple()                                                        --
--   playerId: int                                                          --
--                                                                          --
-- Re-enables camera movement for a player and turns off allowLookAround.   --
-- Does not preserve the current camView or orientation.                    --
-- Faster than unlockCam(), so can be used right before applying a camView. --
--==========================================================================--
libCam.unlockCamSimple = function(playerId)
    -- Unlock camera and reset allowLookAround --
    if (GetLocalPlayer() == Player(playerId)) then
        SetCameraOrientController(gCam.camGhostUnitReset, 0, 0)
        ResetToGameCamera(0)
    end

    -- Cleanup previous dummy unit --
    if (gCam.currCamGhostUnit[playerId+1] ~= nil) then
        RemoveUnit(gCam.currCamGhostUnit[playerId+1])
        gCam.currCamGhostUnit[playerId+1] = nil
    end
end



--===================================================================================--
-- class camView                                                                     --
-- A container for War3 CameraSetupFields, CameraEyePosition, and methods.           --
-- Angles are in degrees.                                                            --
-- If a property is set to a table, index == playerId+1                              --
-- If a property is set to an empty table or nil, the current in-game value is used. --
--===================================================================================--
libCam.camView = setmetatable({
    Name = "New Cam View",

    --== Position ==--
    CamLocX    = {},  -- X-coordinate of camera
    CamLocY    = {},  -- Y-coordinate of camera
    OffsetZ    = {},  -- Z-height of camera from the ground
    TargetDist = {},  -- Length along Line Of Sight between camera and ground. Overridden every time FOV is set.

    --== Orientation ==--
    AngleOfAtk = {},  -- Pitch.    0°: forward    90°: up              180°: backward       270°: down
    Roll       = {},  -- Roll.     0°: upright    90°: tilted right    180°: upside down    270°: tilted left
    Rotation   = {},  -- Yaw.      0°: east       90°: north           180°: west           270°: south
    LocalPitch = {},  -- Also pitch. local?
    LocalRoll  = {},  -- Also roll.  local?
    LocalYaw   = {},  -- Also yaw.   local?

    --== View ==--
    FOV        = {},  -- Angle of a camera's cone-shaped view. If changed, TargetDist is recalculated and overridden.
    NearZ      = {},  -- Length of an inner layer of absolute fog.
    FarZ       = {},  -- Length along LOS before absolute fog is rendered instead of gameworld.

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        setmetatable(o, {__index = self})
        return o
    end,

    --====================================--
    -- camView:apply()                    --
    --   playerId: int                    --
    --                                    --
    -- Applies this camView for a player. --
    --====================================--
    apply = function(self, playerId)
        libCam.unlockCamSimple(playerId)
        if (GetLocalPlayer() == Player(playerId)) then
            local x = helper.getProperty(self.CamLocX, playerId+1, GetCameraEyePositionX())
            local y = helper.getProperty(self.CamLocY, playerId+1, GetCameraEyePositionY())
            local k = helper.getProperty(self.OffsetZ, playerId+1)
            local j = helper.getProperty(self.TargetDist, playerId+1)

            local a = helper.getProperty(self.AngleOfAtk, playerId+1)
            local h = helper.getProperty(self.Roll, playerId+1)
            local i = helper.getProperty(self.Rotation, playerId+1)
            local d = helper.getProperty(self.LocalPitch, playerId+1)
            local e = helper.getProperty(self.LocalRoll, playerId+1)
            local f = helper.getProperty(self.LocalYaw, playerId+1)

            local c = helper.getProperty(self.FOV, playerId+1)
            local g = helper.getProperty(self.NearZ, playerId+1)
            local b = helper.getProperty(self.FarZ, playerId+1)

            SetCameraPosition(x, y)
            if (a ~= nil) then SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, a, 0) end
            if (b ~= nil) then SetCameraField(CAMERA_FIELD_FARZ, b, 0) end
            if (c ~= nil) then SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, c, 0) end
            if (d ~= nil) then SetCameraField(CAMERA_FIELD_LOCAL_PITCH, d, 0) end
            if (e ~= nil) then SetCameraField(CAMERA_FIELD_LOCAL_ROLL, e, 0) end
            if (f ~= nil) then SetCameraField(CAMERA_FIELD_LOCAL_YAW, f, 0) end
            if (g ~= nil) then SetCameraField(CAMERA_FIELD_NEARZ, g, 0) end
            if (h ~= nil) then SetCameraField(CAMERA_FIELD_ROLL, h, 0) end
            if (i ~= nil) then SetCameraField(CAMERA_FIELD_ROTATION, i, 0) end
            if (j ~= nil) then SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, j, 0) end
            if (k ~= nil) then SetCameraField(CAMERA_FIELD_ZOFFSET, k, 0) end
        end
    end
    },{

    --===========--
    -- Metatable --
    --===========--
    
})



--===================================================================================--
-- class terrainFog                                                                  --
-- A container for War3 Terrain Fog fields and methods.                              --
-- If a property is set to a table, index == playerId+1                              --
-- If a property is set to an empty table or nil, the current in-game value is used. --
--===================================================================================--
libCam.terrainFog = setmetatable({
    Name = "New Terrain Fog",
    FogStartZ  = {},  -- Distance from the start of a gradual terrain fog layer that can be colored. At this point, terrain fog color is completely transparent.
    FogEndZ    = {},  -- Distance from the end of the gradual terrain fog layer. Past this point, terrain fog color is completely opaque.
    FogStyle   = {},  -- 0 = Linear,  1 = Exponential One,  2 = Exponential Two
    FogDensity = {},  -- Opacity multiplier of terrain fog layer.
    FogColorR  = {},  -- Red in RGB color of terrain fog layer.
    FogColorG  = {},  -- Green in RGB color of terrain fog layer.
    FogColorB  = {},  -- Blue in RGB color of terrain fog layer.

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        setmetatable(o, {__index = self})
        return o
    end,

    --=======================================--
    -- terrainFog:apply()                    --
    --   playerId: int                       --
    --                                       --
    -- Applies this terrainFog for a player. --
    --=======================================--
    apply = function(self, playerId)
        local n = helper.getProperty(self.FogStartZ, playerId+1, gCam.currTerrainFogs[playerId+1].FogStartZ)
        local o = helper.getProperty(self.FogEndZ, playerId+1, gCam.currTerrainFogs[playerId+1].FogEndZ)
        local m = helper.getProperty(self.FogStyle, playerId+1, gCam.currTerrainFogs[playerId+1].FogStyle)
        local p = helper.getProperty(self.FogDensity, playerId+1, gCam.currTerrainFogs[playerId+1].FogDensity)
        local q = helper.getProperty(self.FogColorR, playerId+1, gCam.currTerrainFogs[playerId+1].FogColorR)
        local r = helper.getProperty(self.FogColorG, playerId+1, gCam.currTerrainFogs[playerId+1].FogColorG)
        local s = helper.getProperty(self.FogColorB, playerId+1, gCam.currTerrainFogs[playerId+1].FogColorB)

        if (GetLocalPlayer() == Player(playerId)) then
            SetTerrainFogEx(m, n, o, p, q, r, s)
        end

        -- Record properties that can't be fetched from the War3 API --
        gCam.currTerrainFogs[playerId+1].FogStartZ = n
        gCam.currTerrainFogs[playerId+1].FogEndZ = o
        gCam.currTerrainFogs[playerId+1].FogStyle = m
        gCam.currTerrainFogs[playerId+1].FogDensity = p
        gCam.currTerrainFogs[playerId+1].FogColorR = q
        gCam.currTerrainFogs[playerId+1].FogColorG = r
        gCam.currTerrainFogs[playerId+1].FogColorB = s
    end
    },{

    --===========--
    -- Metatable --
    --===========--
    
})



--==============================================================================--
-- class camViewButton                                                          --
-- A button that applies a camView, terrainFog, and/or locks to a camGhostUnit. --
--==============================================================================--
libCam.camViewButton = setmetatable({
    Name = "New Cam View Button",

    --== Read-Only ==--
    Trig    = nil,  -- Trigger for Button FrameEvents.

    --== Trig Automatically Updates Whenever These Properties Are Changed ==--
    Button  = nil,  -- Name of War3 Frame. When clicked, applies all of the below.
    CamView = nil,  -- camView to apply.
    Fog     = nil,  -- terrainFog to apply.
    CGU     = nil,  -- camGhostUnit to lock the cam to.

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        setmetatable(o, {__index = self})
        local tbl = table2.supaTable:new(o)

        tbl:setReadOnly(true, "Trig", false, false)

        tbl:watchProp(function(t,k,v)
            t:updateTrigger()
        end, "Button", false)

        tbl:watchProp(function(t,k,v)
            t:updateTrigger()
        end, "CamView", false)

        tbl:watchProp(function(t,k,v)
            t:updateTrigger()
        end, "Fog", false)

        tbl:watchProp(function(t,k,v)
            t:updateTrigger()
        end, "CGU", false)

        tbl:updateTrigger()
        return tbl
    end,

    --<< PRIVATE METHODS >>--
    --===========================================================--
    -- camViewButton:updateTrigger()                             --
    --   runtime: boolean = true                                 --
    --                                                           --
    -- Deletes the current trigger.                              --
    -- Creates a new one based on Button, CamView, Fog, and CGU. --
    -- If used in code running before gamestart                  --
    --   (i.e. not a FrameEvent), set runtime = true.            --
    --===========================================================--
    updateTrigger = function(self, runtime)
        if (runtime == nil) then runtime = true end
        local tbl = getmetatable(self).__index
        
        local func = function()
            if (self.Trig ~= nil) then
                DestroyTrigger(self.Trig)
                tbl.Trig = nil
            end

            if ((self.Button ~= nil) and ((self.CamView ~= nil) or (self.Fog ~= nil) or (self.CGU ~= nil))) then
                tbl.Trig = CreateTrigger()
                BlzTriggerRegisterFrameEvent(self.Trig, BlzGetFrameByName(self.Button, 0), FRAMEEVENT_CONTROL_CLICK)

                TriggerAddAction(self.Trig, function()
                    local trigPlayerId = GetPlayerId(GetTriggerPlayer())
                    if (self.CamView ~= nil) then
                        self.CamView:apply(trigPlayerId)
                    end
                    if (self.Fog ~= nil) then
                        self.Fog:apply(trigPlayerId)
                    end
                    if ((self.CGU ~= nil) and (GetLocalPlayer() == Player(trigPlayerId))) then
                        SetCameraTargetController(self.CGU, 0, 0, false)
                    end
                end)
            end
        end

        if (runtime == true) then
            libTrig.executeAtRuntime(func, constTrig.runtimeUpdateFrames)
        else
            func()
        end
    end
    },{

    --===========--
    -- Metatable --
    --===========--

})



--=========--
return libCam
--=========--
