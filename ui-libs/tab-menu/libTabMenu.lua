--=================--
local libTabMenu = {}
--=================--

-- < Modules > --
local table2 = require "table2"

-- < References > --
local constTabMenu = require "constTabMenu"



--====================================================--
-- class tabMenuEntry                                 --
-- Contains all customizable properties of one entry. --
--====================================================--
libTabMenu.tabMenuEntry = setmetatable({
    Name = "New Tab Menu Entry",

    --== Text ==--
    Label = "",  -- Text shown on tab button
    Title = "",  -- Title text
    Desc1 = "",  -- Text in left description box
    Desc2 = "",  -- Text in right description box

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        setmetatable(o, {__index = self})
        local tbl = table2.supaTable:new(o)

        return tbl
    end,
    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--===============================================--
-- class tabMenu                                 --
-- Handles creating and updating TabMenu Frames. --
--===============================================--
libTabMenu.tabMenu = setmetatable({
    Name = "New Tab Menu",

    --== Auto-Update On Change ==--
    Entries   = {},     -- tabMenuEntry class objects
    BoardMode = false,  -- If game has a leaderboard, set this to true, to avoid blocking buttons.

    --== Read-Only ==--
    Frame,                -- Framehandle for main parent frame
    TabSliderTrig,        -- Trigger to scroll tab buttons with slider
    TabButtonTrigs = {},  -- Triggers to update text when tab buttons are clicked
    TabSkip        = 0,   -- Number of leftmost tab in current slider position, starting from 0.
    TabCurrent     = 0,   -- Number of currently clicked tab button (0-4). Up to 5 tab buttons visible at one time. 
    TabPosOffset   = 0,   -- How much the position/width of tabs are adjusted to simulate scrolling
    
    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}

        -- Init empty table properties --
        if (o.Entries == nil) then o.Entries = {} end
        if (o.TabButtonTrigs == nil) then o.TabTrigs = {} end

        -- Init default params and methods --
        setmetatable(o, {__index = self})

        -- Init supatable functionality --
        local tbl = table2.supaTable:new(o)
        
        -- Create Frame --
        tbl.Frame = BlzCreateFrame("TabMenu", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        BlzFrameSetAbsPoint(tbl.Frame, FRAMEPOINT_TOPLEFT, 0.02, 0.553)

        -- Init all frame children --
        tbl:updateFrame()
        tbl:updateTabBar()
        tbl:initTabButtons()
        tbl:initTabSlider()

        -- supaTable: Auto-update frame --
        tbl:watchProp(function(t,k,v)
            tbl:updateTabBar()
        end, "Entries", true)

        tbl:watchProp(function(t,k,v)
            tbl:updateFrame()
        end, "BoardMode", false)

        -- supaTable: Set read-only properties --
        tbl:setReadOnly(true, "Frame")
        tbl:setReadOnly(true, "TabSliderTrig")
        tbl:setReadOnly(true, "TabButtonTrigs")
        tbl:setReadOnly(true, "TabSkip")
        tbl:setReadOnly(true, "TabCurrent")
        tbl:setReadOnly(true, "TabPosOffset")

        -- Return --
        return tbl
    end,

    --<< PRIVATE METHODS >>--
    --========================================================--
    -- tabMenu:updateFrame()                                  --
    --                                                        --
    -- Positions CloseButton to be compatible with BoardMode. --
    --========================================================--
    updateFrame = function(self)
        local closeButton = BlzFrameGetChild(self.Frame, 1)
        local tabBar = BlzFrameGetChild(self.Frame, 2)

        if (self.BoardMode == false) then
            local closeButtonX = constTabMenu.borderSize
            local closeButtonY = -constTabMenu.borderSize
            local tabBarX = (constTabMenu.menuSize * constTabMenu.closeButtonWidth) + constTabMenu.borderSize
            local tabBarY = -constTabMenu.borderSize
            BlzFrameSetPoint(closeButton, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, closeButtonX, closeButtonY)
            BlzFrameSetPoint(tabBar, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, tabBarX, tabBarY)
        else
            local closeButtonX = (constTabMenu.menuSize * constTabMenu.tabBarWidth) + constTabMenu.borderSize
            local closeButtonY = -constTabMenu.borderSize
            local tabBarX = constTabMenu.borderSize
            local tabBarY = -constTabMenu.borderSize
            BlzFrameSetPoint(closeButton, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, closeButtonX, closeButtonY)
            BlzFrameSetPoint(tabBar, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, tabBarX, tabBarY)
        end
    end,


    --============================================--
    -- tabMenu:updateTabBar()                     --
    --                                            --
    -- Unhides a button for each entry (up to 5). --
    -- Updates button label text.                 --
    --============================================--
    updateTabBar = function(self)
        local tabBar = BlzFrameGetChild(self.Frame, 2)

        -- Unhide tab buttons and update labels as entries increase --
        for i=1, math.min(5, #self.Entries) do
            local tab = BlzFrameGetChild(tabBar, i-1)
            local textTab = BlzFrameGetChild(tab, 5)
            local entryNum = self.TabSkip + i
            BlzFrameSetVisible(tab, true)
            BlzFrameSetText(textTab, self.Entries[entryNum].Label)
        end

        -- Hide tab buttons as entries decrease --
        for i=(#self.Entries), 5 do
            local tab = BlzFrameGetChild(tabBar, i-1)
            BlzFrameSetVisible(tab, false)
        end
    end,

    --================================================--
    -- tabMenu:updateText()                           --
    --                                                --
    -- Updates text to show currently selected Entry. --
    --================================================--
    updateText = function(self)

    end,

    --==================================--
    -- tabMenu:initTabButtons()         --
    --                                  --
    -- Create triggers that change text --
    -- when tab buttons are clicked.    --
    --==================================--
    initTabButtons = function(self)

    end,

    --=============================================--
    -- tabMenu:initTabSlider()                     --
    --                                             --
    -- Updates the trigger for the tab bar slider. --
    --=============================================--
    initTabSlider = function(self)
        local tabBar = BlzFrameGetChild(self.Frame, 2)
        local tabSlider = BlzFrameGetChild(self.Frame, 3)
        
        local tab0 = BlzFrameGetChild(tabBar, 0)
        local tab1 = BlzFrameGetChild(tabBar, 1)
        local tab2 = BlzFrameGetChild(tabBar, 2)
        local tab3 = BlzFrameGetChild(tabBar, 3)
        local tab4 = BlzFrameGetChild(tabBar, 4)

        local textTab0 = BlzFrameGetChild(tab0, 5)
        local textTab1 = BlzFrameGetChild(tab1, 5)
        local textTab2 = BlzFrameGetChild(tab2, 5)
        local textTab3 = BlzFrameGetChild(tab3, 5)
        local textTab4 = BlzFrameGetChild(tab4, 5)

        local tabWidth = constTabMenu.menuSize * constTabMenu.tabWidth
        local tabHeight = constTabMenu.menuSize * constTabMenu.tabHeight
        
        -- Update tabs every time slider changes --
        local newTrig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(newTrig, tabSlider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
        TriggerAddAction(newTrig, function()

            -- Slider does nothing if 4 or less tabs --
            if (#self.Entries < 5) then return end

            -- Quick maffs --
            local sliderValue = BlzGetTriggerFrameValue()
            local sliderRangePerTab = constTabMenu.sliderRange / (#self.Entries - 4)

            -- Manually set read-only values (supaTable) --
            getmetatable(self).__index.TabPosOffset = tabWidth * ((sliderValue % sliderRangePerTab) / sliderRangePerTab)
            getmetatable(self).__index.TabSkip = math.floor(sliderValue / sliderRangePerTab)

            -- Adjust width and position of tabs to simulate scrolling --
            local tabWidth0 = tabWidth - self.TabPosOffset
            local tabWidth1 = tabWidth
            local tabWidth2 = tabWidth
            local tabWidth3 = tabWidth
            local tabWidth4 = self.TabPosOffset
            
            local tabPosX0 = 0
            local tabPosX1 = tabWidth0
            local tabPosX2 = tabWidth0 + tabWidth1
            local tabPosX3 = tabWidth0 + tabWidth1 + tabWidth2
            local tabPosX4 = tabWidth0 + tabWidth1 + tabWidth2 + tabWidth3

            BlzFrameSetSize(tab0, tabWidth0, tabHeight)
            BlzFrameSetSize(tab4, tabWidth4, tabHeight)
            BlzFrameSetPoint(tab1, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, tabPosX1, 0)
            BlzFrameSetPoint(tab2, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, tabPosX2, 0)
            BlzFrameSetPoint(tab3, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, tabPosX3, 0)
            BlzFrameSetPoint(tab4, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, tabPosX4, 0)
            
            -- Set tab labels --
            BlzFrameSetText(textTab0, self.Entries[self.TabSkip+1].Label)
            BlzFrameSetText(textTab1, self.Entries[self.TabSkip+2].Label)
            BlzFrameSetText(textTab2, self.Entries[self.TabSkip+3].Label)
            BlzFrameSetText(textTab3, self.Entries[self.TabSkip+4].Label)
            BlzFrameSetText(textTab4, self.Entries[self.TabSkip+5].Label)
        end)

        -- Clean up old trigger and replace it with new trigger --
        if (self.TabSliderTrig ~= nil) then
            DestroyTrigger(self.TabSliderTrig)
            self.TabSliderTrig = nil
        end
        self.TabSliderTrig = newTrig
    end,
    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--=============--
return libTabMenu
--=============--
