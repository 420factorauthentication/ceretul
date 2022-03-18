--=====--
gCCG = {}
--=====--

-- < Modules > --
local libCCG = require "libCCG"



--------------------------
-- CCG System Variables --
--------------------------
gCCG.currHoveredCardInst = nil    -- Current local player large card shown on mouse-over
gCCG.isMouseDown         = false  -- Is local players mouse1 down?
gCCG.mouseDownTrig       = {}     -- Global player mousedown trig. Index == PlayerID
gCCG.mouseUpTrig         = {}     -- Global player mouseup trigs. Index == PlayerId
gCCG.mouseMoveTrig       = {}     -- Global player mousemove trig. Index == PlayerId



-----------
-- Cards --
-----------
gCCG.cardInstances = {}
