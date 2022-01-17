-- < Modules > --
local libTrig = require "libTrig"

-- < References > --
local constTrig = require "constTrig"






--==============================--
--==============================--
local loadingScreenUI = function()

end






--==============================--
--==============================--
local preRuntimeUI = function()
    --== Reveal entire map for all players ==--
    FogEnable(false)
    FogMaskEnable(false)

    -------------------
    -- Origin Frames --
    -------------------
    --== Hide Bottom Console ==--
    -- BlzEnableUIAutoPosition(false)
    -- BlzFrameSetAbsPoint(BlzGetFrameByName("ConsoleUI", 0), FRAMEPOINT_BOTTOM, 0.0, -0.18)
end






--============================--
--============================--
local postRuntimeUI = function()
    -------------------
    -- Origin Frames --
    -------------------
    --== Prevent multiplayer desyncs by forcing the creation of the QuestDialog frame ==--
    BlzFrameClick(BlzGetFrameByName("UpperButtonBarQuestsButton", 0))
    ForceUICancel()

    --== Hide Idle Workers Button ==--
    BlzFrameSetVisible(BlzFrameGetChild(BlzGetFrameByName("ConsoleUI", 0), 7), false)

    --== Hide Hero Bar ==--
    BlzFrameSetVisible(BlzGetOriginFrame(ORIGIN_FRAME_HERO_BAR, 0), false)

    --TEST: CREATE QUEST--
    local quest = CreateQuest()
    QuestSetTitle(quest, "title")
    QuestSetDescription(quest, "description")
    QuestSetDiscovered(quest, true)

    --TEST: NEW QUEST DIALOG--
    local newQuestDialog = BlzCreateFrame("TabMenu", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
    BlzFrameSetAbsPoint(newQuestDialog, FRAMEPOINT_TOPLEFT, 0.02, 0.553)
    BlzFrameSetLevel(newQuestDialog, 1)
    BlzFrameSetVisible(newQuestDialog, false)
    
    -- TEST: OVERRIDE QUEST BUTTON --
    local newQuestDialogAction = function() BlzFrameSetVisible(newQuestDialog, true) end
    local newQuestDialogTrig = CreateTrigger()
    TriggerAddAction(newQuestDialogTrig, newQuestDialogAction)
    BlzTriggerRegisterFrameEvent(newQuestDialogTrig, BlzGetFrameByName("UpperButtonBarQuestsButton", 0), FRAMEEVENT_CONTROL_CLICK)
end






--================================--
--============= Main =============--
loadingScreenUI()
preRuntimeUI()
libTrig.executeAtRuntime(postRuntimeUI, constTrig.runtimeInitFrames)
