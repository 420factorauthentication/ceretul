-- < Modules > --
local libUnitAtk = require "libUnitAtk"



--== TEST: LOCAL TABLE PASSED TO TRIGGER: WORKS ==--
-- local asdf = function()
--     local table = {}
--     table.number = 1

--     local asdfTimerTrig = CreateTrigger()
--     TriggerAddAction(asdfTimerTrig, function()
--         print(table.number)
--         table.number = table.number + 1
--     end)
--     TriggerRegisterTimerEventPeriodic(asdfTimerTrig, 0.5)

--     local asdfCleanupTrig = CreateTrigger()
--     TriggerAddAction(asdfCleanupTrig, function()
--         DestroyTrigger(asdfTimerTrig)
--         DestroyTrigger(asdfCleanupTrig)
--     end)
--     TriggerRegisterTimerEventSingle(asdfCleanupTrig, 3)
-- end
-- asdf()

--== TEST: LOCAL NUMBER PASSED TO TRIGGER: WORKS ==--
-- local foobar = function()
--     local number = 1

--     local foobarTimerTrig = CreateTrigger()
--     TriggerAddAction(foobarTimerTrig, function()
--         print(number)
--         number = number + 1
--     end)
--     TriggerRegisterTimerEventPeriodic(foobarTimerTrig, 0.5)

--     local foobarCleanupTrig = CreateTrigger()
--     TriggerAddAction(foobarCleanupTrig, function()
--         DestroyTrigger(foobarTimerTrig)
--         DestroyTrigger(foobarCleanupTrig)
--     end)
--     TriggerRegisterTimerEventSingle(foobarCleanupTrig, 3)
-- end
-- foobar()


--== TEST: ATTACK ==--
local newAttack = libUnitAtk.slash:new({
    DmgFlatAmount = 50,

    TimeStart  = 0,
    TimeLength = 4,
    Keyframes  = 4,

    StartMinX = -400,
    StartMaxX = -200,
    StartMinY = 200,
    StartMaxY = 400,

    EndMinX = 200,
    EndMaxX = 400,
    EndMinY = 200,
    EndMaxY = 400,

    OriginVFX = {"Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster"},
    MotionVFX = {"Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster"},
    TargetVFX = {"Abilities\\Spells\\Human\\ThunderClap\\ThunderClapTarget"},
})

local footman = CreateUnit(Player(0), FourCC("hfoo"), 0, 0, 0)

CreateUnit(Player(3), FourCC("hpea"), -700, 300, 0)
CreateUnit(Player(3), FourCC("hpea"), -500, 300, 0)

CreateUnit(Player(3), FourCC("hpea"), -300, 300, 0)
CreateUnit(Player(3), FourCC("hpea"), -100, 300, 0)
CreateUnit(Player(3), FourCC("hpea"),  100, 300, 0)
CreateUnit(Player(3), FourCC("hpea"),  300, 300, 0)

CreateUnit(Player(3), FourCC("hpea"),  500, 300, 0)
CreateUnit(Player(3), FourCC("hpea"),  700, 300, 0)

local attackKeyPress = CreateTrigger()
BlzTriggerRegisterPlayerKeyEvent(attackKeyPress, Player(0), OSKEY_SPACE, 0, false)
TriggerAddAction(attackKeyPress, function()
    newAttack:launch(footman)
    print("launched attack")
end)
