--==================--
local libUnitMove = {}
--==================--

-- < Modules > --
local math2 = require "math2"
local table2 = require "table2"



--=======================================--
-- class unitMove2D                      --
--                                       --
-- One instance handles movement         --
-- of a single unit for a single player. --
--=======================================--
libUnitMove.unitMove2D = setmetatable({
    Name = "New Player Controller",

    --== Auto-Update Functionality On Change ==--
    PlayerId,            -- int. Change to set which player this controls.
    Unit,                -- (native) unithandle. Change to set which unit is controlled by movement.
    Speed    = 270,      -- Movespeed
    KeyUp    = OSKEY_W,  -- (native) oskeytype. Keybind to move up
    KeyLeft  = OSKEY_A,  -- (native) oskeytype. Keybind to move left
    KeyDown  = OSKEY_S,  -- (native) oskeytype. Keybind to move down
    KeyRight = OSKEY_D,  -- (native) oskeytype. Keybind to move right
    Enabled  = true,     -- Change to enable or disable movement

    --== Read-Only ==--
    CurrVec,          -- math2.vec3. Current movement vector based on pressed keys.
    IsUp    = false,  -- Is the player currently pressing Up key
    IsLeft  = false,  -- Is the player currently pressing Left key
    IsDown  = false,  -- Is the player currently pressing Down key
    IsRight = false,  -- Is the player currently pressing Right key
    Trigs   = {},     -- Triggers used for movement

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}

        -- Init empty table properties --
        o.Trigs = {}

        -- Init default params and methods --
        o.CurrVec = math2.vec3:new()
        setmetatable(o, {__index = self})

        -- This class is a supaTable --
        local tbl = table2.supaTable:new(o)

        -- Set read-only properties (supaTable) --
        tbl:setReadOnly(true, "CurrVec")
        tbl:setReadOnly(true, "IsUp")
        tbl:setReadOnly(true, "IsLeft")
        tbl:setReadOnly(true, "IsDown")
        tbl:setReadOnly(true, "IsRight")
        tbl:setReadOnly(true, "Trigs")

        -- Auto-update movement functionality (supaTable) --
        tbl:watchProp(function(t,k,v)
            tbl:initKeyPressTrigs()
        end, "PlayerId", false)

        tbl:watchProp(function(t,k,v)
            tbl:initKeyPressTrigs()
        end, "KeyUp", false)

        tbl:watchProp(function(t,k,v)
            tbl:initKeyPressTrigs()
        end, "KeyLeft", false)

        tbl:watchProp(function(t,k,v)
            tbl:initKeyPressTrigs()
        end, "KeyDown", false)

        tbl:watchProp(function(t,k,v)
            tbl:initKeyPressTrigs()
        end, "KeyRight", false)

        -- Main --
        tbl:initMainMovementTrig()
        tbl:initKeyPressTrigs()

        return tbl
    end,


    -------------------------
    --<< PRIVATE METHODS >>--
    -------------------------
    initMainMovementTrig = function(self)
        local updatePeriod = 1/60
        getmetatable(self.Trigs).__index.Main = CreateTrigger()  --Set read-only prop (supaTable)
        DisableTrigger(self.Trigs.Main)
        TriggerRegisterTimerEventPeriodic(self.Trigs.Main, updatePeriod)
        TriggerAddAction(self.Trigs.Main, function()
            self:move(updatePeriod)
        end)
    end,


    initKeyPressTrigs = function(self)
        if (self.PlayerId == nil) then return end

        -- Used to set read-only properties (supaTable) --
        local tbl = getmetatable(self).__index
        local tblTrigs = getmetatable(self.Trigs).__index
        
        -- For each event type --
        local inputs = {
            "Up",
            "Left",
            "Down",
            "Right"
        }

        for k, v in pairs(inputs) do
            -- Cleanup old KeyPress trig --
            if ((self.Trigs[v .. "Press"] ~= nil)) then
                DestroyTrigger(self.Trigs[v .. "Press"])
            end

            -- Cleanup old KeyRelease trig --
            if (self.Trigs[v .. "Release"] ~= nil) then
                DestroyTrigger(self.Trigs[v .. "Release"])
            end

            if (GetPlayerSlotState(Player(self.PlayerId)) == PLAYER_SLOT_STATE_PLAYING) then
                -- New KeyPress trig --
                tblTrigs[v .. "Press"] = CreateTrigger()
                BlzTriggerRegisterPlayerKeyEvent(self.Trigs[v .. "Press"], Player(self.PlayerId), self["Key" .. v], 0, true)
                TriggerAddAction(self.Trigs[v .. "Press"], function()

                    -- Update movement calculations --
                    if (self["Is" .. v] == true) then return end
                    tbl["Is" .. v] = true
                    self:updateMovementVector()

                    -- Only turn on trig while moving --
                    local delayCompensationFactor = 0.04
                    if (self.CurrVec:length() > 0) then
                        self:move(delayCompensationFactor) --delay fix
                        EnableTrigger(self.Trigs.Main)
                    end
                end)

                -- New KeyRelease trig --
                tblTrigs[v .. "Release"] = CreateTrigger()
                BlzTriggerRegisterPlayerKeyEvent(self.Trigs[v .. "Release"], Player(self.PlayerId), self["Key" .. v], 0, false)
                TriggerAddAction(self.Trigs[v .. "Release"], function()

                    -- Update movement calculations --
                    tbl["Is" .. v] = false
                    self:updateMovementVector()

                    -- Turn off trig while not moving --
                    if (self.CurrVec:length() == 0) then
                        DisableTrigger(self.Trigs.Main)
                    end
                end)
            end
        end
    end,


    updateMovementVector = function(self)
        local x = 0
        if (self.IsLeft)  then x = x - 1 end
        if (self.IsRight) then x = x + 1 end
        
        local y = 0
        if (self.IsDown) then y = y - 1 end
        if (self.IsUp)   then y = y + 1 end
        
        -- Set read-only props (supaTable) --
        local tbl = getmetatable(self).__index
        local tblCurrVec = getmetatable(self.CurrVec).__index
        tblCurrVec.x = x
        tblCurrVec.y = y
        tblCurrVec:normalize()
    end,


    move = function(self, scalar)
        if (self.Unit == nil) then return end
        if (self.Enabled ~= true) then return end
        scalar = scalar or 1
        local newX = GetUnitX(self.Unit) + (self.Speed * self.CurrVec.x * scalar)
        local newY = GetUnitY(self.Unit) + (self.Speed * self.CurrVec.y * scalar)
        if (IsTerrainPathable(newX, newY, PATHING_TYPE_ANY)) then
            SetUnitPosition(self.Unit, newX, newY)
        end
    end,
    },{

    --===========--
    -- Metatable --
    --===========--

})



--==============--
return libUnitMove
--==============--
