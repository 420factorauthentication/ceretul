--==============--
local libTrig = {}
--==============--

-- < Modules > --
local libPlayer = require "libPlayer"



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



--===============================================================================--
-- executeAtRuntime()                                                            --
--   func: function with no args                                                 --
--   priority: int >= 0                                                          --
--                                                                               --
-- Use to execute some code at game start, rather than during loading/compiling. --
-- Priority 0 runs first, then 1, then 2, etc.                                   --
--===============================================================================--
libTrig.executeAtRuntime = function(func, priority)
    priority = math.abs(priority)
    local trig_runtime = CreateTrigger()
    local action = function()
        func()
        DestroyTrigger(trig_runtime)
    end
    TriggerAddAction(trig_runtime, action)
    TriggerRegisterTimerEventSingle(trig_runtime, ((0.01 * priority) + 0.01))
end



--==========--
return libTrig
--==========--
