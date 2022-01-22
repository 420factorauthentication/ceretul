-- < Modules > --
local libTrig = require "libTrig"
local libTabMenu = require "libTabMenu"

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
    
    --TEST: OVERRIDE QUEST BUTTON--
    -- local newQuestDialogAction = function() BlzFrameSetVisible(newQuestDialog, true) end
    -- local newQuestDialogTrig = CreateTrigger()
    -- TriggerAddAction(newQuestDialogTrig, newQuestDialogAction)
    -- BlzTriggerRegisterFrameEvent(newQuestDialogTrig, BlzGetFrameByName("UpperButtonBarQuestsButton", 0), FRAMEEVENT_CONTROL_CLICK)

    -- --TEST: NEW BLANK TAB MENU--
    -- local newTabMenu = libTabMenu.tabMenu:new({
    -- })

    --TEST: NEW TAB MENU--
    local newTabMenu = libTabMenu.tabMenu:new({
        Entries = {
            libTabMenu.tabMenuEntry:new({
                Label = "Tab 0",
                Title = "Tab 0",
                Desc1 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec in justo at felis pretium varius vitae eu justo. Phasellus porta dolor libero, nec placerat enim rutrum ac. Fusce ornare accumsan diam, dapibus volutpat ligula rutrum sed. Nullam sagittis aliquet accumsan. Fusce laoreet auctor magna, et tristique mauris posuere sed. Nunc mollis mi ut est sodales, nec tristique nibh dapibus. Nulla ultricies ornare dui. Vestibulum pharetra facilisis lacinia. Aenean pharetra ornare hendrerit. Etiam in libero lacinia, faucibus ipsum sed, aliquet eros. Morbi consequat dictum quam eu fermentum. Nam quis viverra nisl. Nullam id orci sed nulla euismod placerat placerat quis sapien. Pellentesque posuere risus fermentum, tincidunt arcu eu, facilisis purus. Nullam bibendum elit arcu, sollicitudin faucibus tellus malesuada ut. Nullam condimentum semper libero. Vivamus lacinia auctor ligula quis tempor. Suspendisse vel magna purus. Proin malesuada eu justo vehicula placerat. Nullam suscipit ipsum in orci pellentesque tristique. Nunc ut dui purus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Duis sodales, justo a placerat ultricies, purus lectus sagittis lacus, semper posuere arcu nunc ac mi.",
                Desc2 = "Vestibulum risus orci, vestibulum quis ex ultricies, rhoncus feugiat nulla. Ut ultrices lectus fermentum sodales aliquam. Curabitur quis dolor et ipsum viverra consequat. Aliquam erat volutpat. Integer aliquet turpis mi, a maximus ante dapibus ut. Nam varius nulla dui, mollis porttitor dui semper sed. Cras mattis porttitor ex, at varius tellus ullamcorper sagittis. Nulla eget ultrices mi, eget euismod eros. Ut sollicitudin suscipit mauris a viverra. Nullam tincidunt, ipsum id consectetur blandit, libero tellus efficitur metus, ac sagittis massa risus sed ex. Vestibulum aliquet tortor eget leo varius, ut aliquam quam suscipit. Fusce risus ipsum, lobortis at varius et, congue id purus. Maecenas iaculis erat non risus auctor pulvinar. Sed quis risus nec nunc lobortis dictum in et lacus. Aliquam ac bibendum mauris, non hendrerit neque. Mauris gravida dui quis diam mollis, at sagittis sapien dictum. Nulla orci libero, congue at malesuada vel, pharetra et nisl. Mauris volutpat finibus feugiat. Curabitur a dui ut ipsum mollis porta vitae sed urna. Mauris rhoncus ligula ut felis sagittis, sit amet venenatis dolor iaculis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam egestas mattis rutrum.",
            }),

            libTabMenu.tabMenuEntry:new({
                Label = "Tab 1",
                Title = "Tab 1",
                Desc1 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas id metus dignissim, faucibus tortor eget, porta enim. Proin convallis nibh at tortor consequat, at blandit tellus molestie. Praesent at nisi sagittis, luctus nisl non, hendrerit est. Morbi urna velit, volutpat faucibus augue at, auctor ultrices tellus. Ut eleifend id odio id tristique. Integer non dolor purus. Aliquam ut augue porttitor, rutrum leo quis, lacinia elit. Mauris velit purus, congue quis tortor sed, dapibus molestie felis. Proin egestas semper sagittis. Nulla facilisi. Duis ipsum neque, ornare eu neque a, elementum posuere tellus. Etiam ultricies, enim ac iaculis porttitor, enim libero malesuada ante, in ultricies purus urna et libero. Donec non tincidunt metus. Nunc interdum, tortor vitae cursus feugiat, sapien metus viverra nulla, sit amet lobortis nisi nulla sit amet risus. Aliquam consectetur dapibus dui, non venenatis orci ornare vel. Aliquam consectetur eros vitae nibh fringilla vulputate. Morbi id nisl ac dui sagittis pharetra eget eu lectus. In sodales neque et est porttitor, at commodo velit accumsan. Sed euismod ut lectus eget imperdiet. Sed venenatis tincidunt consectetur.",
                Desc2 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam consequat placerat commodo. Vestibulum commodo ex et elit scelerisque ultrices. Aliquam sit amet magna dictum, hendrerit nisi eleifend, fringilla nulla. Cras nec ex a dolor volutpat porttitor. Sed a aliquet est. Cras vestibulum nisi diam, at rutrum leo efficitur ultricies. Praesent rutrum vulputate ante, at elementum est suscipit ac. Nulla suscipit vel orci aliquet maximus. Pellentesque suscipit nunc quis arcu lacinia, quis interdum enim commodo. Maecenas posuere aliquet nunc sed malesuada. Nam vitae sapien ut ligula facilisis ultrices. Suspendisse convallis congue risus, et placerat tellus finibus id. Nam eu metus enim. In consectetur lectus lacus, at rutrum eros ornare eget. Nam a tincidunt felis. Nulla facilisi. Suspendisse ut risus nunc. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Pellentesque tempus, mauris at tristique condimentum, libero neque vestibulum tortor, sit amet posuere libero magna eget libero.",
            }),

            libTabMenu.tabMenuEntry:new({
                Label = "Tab 2",
                Title = "Tab 2",
                Desc1 = "Lorem",
                Desc2 = "Lorem",
            }),

            libTabMenu.tabMenuEntry:new({
                Label = "Tab 3",
                Title = "Tab 3",
                Desc1 = "Lorem",
                Desc2 = "Lorem",
            }),

            libTabMenu.tabMenuEntry:new({
                Label = "Tab 4",
                Title = "Tab 4",
                Desc1 = "Lorem",
                Desc2 = "Lorem",
            }),

            libTabMenu.tabMenuEntry:new({
                Label = "Tab 5",
                Title = "Tab 5",
                Desc1 = "Lorem",
                Desc2 = "Lorem",
            }),

            libTabMenu.tabMenuEntry:new({
                Label = "Tab 6",
                Title = "Tab 6",
                Desc1 = "Lorem",
                Desc2 = "Lorem",
            }),

            libTabMenu.tabMenuEntry:new({
                Label = "Tab 7",
                Title = "Tab 7",
                Desc1 = "Lorem",
                Desc2 = "Lorem",
            }),
        }
    })
end






--================================--
--============= Main =============--
loadingScreenUI()
preRuntimeUI()
libTrig.executeAtRuntime(postRuntimeUI, constTrig.runtimeInitFrames)
