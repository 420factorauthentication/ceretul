-- < Modules > --
local libUnitMove = require "libUnitMove"



--== TEST: NEW PLAYER CONTROLLER ==--
local peasant = CreateUnit(Player(0), FourCC("hpea"), 0, -400, 0)
local peasant2 = CreateUnit(Player(1), FourCC("hpea"), 0, -400, 0)
local playerController = libUnitMove.unitMove2D:new({
    PlayerId = 0,
    Unit = peasant,
})
-- SetUnitPathing(peasant, false)

--== TEST: FORCEUICANCEL() WORKAROUND TO DRAG SELECTION DISABLING KEYPRESSES ==--
--== WORKS BUT CAN BUG OUT IF SPAMMING KEYPRESSES + MOUSEDOWNS ==--
--== ALSO CAUSES PROBLEMS OPENING BLIZZARD MENUS ==--
EnableDragSelect(false, false)

local dragTrig = CreateTrigger()
TriggerRegisterPlayerEvent(dragTrig, Player(0), EVENT_PLAYER_MOUSE_DOWN)
TriggerAddAction(dragTrig, function()
    print("mouse down")
    ForceUICancel()
end)

--== WORKS: KEYPRESSES NOT DISABLED IF MOUSEDOWN ONTOP OF A FRAME ==--
