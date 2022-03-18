--==============--
local libTrig = {}
--==============--

-- < Modules > --
local libPlayer = require "libPlayer"
local table2 = require "table2"



--===============================================================--
-- registerSyncEventForPlayingPlayers()                          --
--   trig: (native) trigger                                      --
--   prefixBase: string                                          --
--                                                               --
-- Registers a sync event on a trigger for all playing players.  --
-- Each player has a different prefix to trigger the sync event: --
--   prefixBase  +  ","  +  playerId                             --
--===============================================================--
libTrig.registerSyncEventForPlayingPlayers = function(trig, prefixBase)
    for k, v in pairs(libPlayer.getPlayingPlayerIds()) do
        local prefix = prefixBase .. "," .. tostring(v)
        BlzTriggerRegisterPlayerSyncEvent(trig, Player(v), prefix, false)
    end
end



--=========================================--
-- executeAtRuntime()                      --
--   func: function with no args           --
--   deltaTime: real = 0                   --
--                                         --
-- Use to execute some code at game start, --
-- rather than during loading/compiling.   --
-- DeltaTime = secs after runtime start.   --
--  (instant if runtime started already)   --
--=========================================--
libTrig.executeAtRuntime = function(func, deltaTime)
    deltaTime = deltaTime or 0

    -- Execute immediately if game already started --
    if (GLOBAL_RUNTIME_DONE == true) then func() return end

    -- Collect all functions if game hasnt started --
    if (GLOBAL_RUNTIME_FUNCS == nil) then GLOBAL_RUNTIME_FUNCS = {} end
    if (GLOBAL_RUNTIME_FUNCS[deltaTime] == nil) then GLOBAL_RUNTIME_FUNCS[deltaTime] = {} end
    table.insert(GLOBAL_RUNTIME_FUNCS[deltaTime], func)

    -- DeltaTime counter; used to iteratively run functions in order --
    if (GLOBAL_RUNTIME_LASTTIMEOFFSET == nil) then GLOBAL_RUNTIME_LASTTIMEOFFSET = 0 end

    -- One trigger to execute all functions at runtime start --
    if (GLOBAL_RUNTIME_TRIG == nil) then
        GLOBAL_RUNTIME_TRIG = CreateTrigger()
        TriggerAddAction(GLOBAL_RUNTIME_TRIG, function()
            GLOBAL_RUNTIME_DONE = true  --Runtime has started; flag system to stop collecting functions
            
            -- Execute all functions in order at the right DeltaTime --
            for k, v in table2.pairsByKeys(GLOBAL_RUNTIME_FUNCS) do
                if (k > GLOBAL_RUNTIME_LASTTIMEOFFSET) then
                    TriggerSleepAction(k - GLOBAL_RUNTIME_LASTTIMEOFFSET)
                    GLOBAL_RUNTIME_LASTTIMEOFFSET = k
                end
                
                for x, d in table2.pairsByKeys(v) do d() end
            end

            -- Cleanup --
            for k, v in pairs(GLOBAL_RUNTIME_FUNCS) do
                GLOBAL_RUNTIME_FUNCS[k] = nil end
            GLOBAL_RUNTIME_FUNCS = nil
            GLOBAL_RUNTIME_LASTTIMEOFFSET = nil
            DestroyTrigger(GLOBAL_RUNTIME_TRIG)

        end) TriggerRegisterTimerEventSingle(GLOBAL_RUNTIME_TRIG, 0)
    end
end



--==========--
return libTrig
--==========--
