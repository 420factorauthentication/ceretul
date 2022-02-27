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



--=========================================--
-- executeAtRuntime()                      --
--   func: function with no args           --
--   priority: real                        --
--                                         --
-- Use to execute some code at game start, --
-- rather than during loading/compiling.   --
-- Lower priority numbers execute first.   --
--=========================================--
libTrig.executeAtRuntime = function(func, priority)
    -- if (GLOBAL_RUNTIME_ALREADY_EXECUTED ~= nil) then
    --     func() return end

    -- if (GLOBAL_RUNTIME_CODE == nil) then
    --     GLOBAL_RUNTIME_CODE = {} end

    -- if (GLOBAL_RUNTIME_CODE[priority] == nil) then
    --     GLOBAL_RUNTIME_CODE[priority] = {} end

    -- table.insert(GLOBAL_RUNTIME_CODE[priority], func)

    -- if (GLOBAL_RUNTIME_TRIG ~= nil) then
    --     GLOBAL_RUNTIME_TRIG = CreateTrigger()
    --     TriggerAddAction(GLOBAL_RUNTIME_TRIG, function()

    --     end)
    -- end


        





    priority = math.abs(priority)

    local trig_runtime = CreateTrigger()
    TriggerAddAction(trig_runtime, function()
        func()
        DestroyTrigger(trig_runtime)
    end)
    TriggerRegisterTimerEventSingle(trig_runtime, ((0.01 * priority) + 0.01))
end



--==========--
return libTrig
--==========--
