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
        return o
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
    ButtonCurrent,        -- Number of currently clicked tab button (0-4). Up to 5 tab buttons visible at one time.
    EntryCurrent,         -- Entries array index of currently clicked tab button, starting from 1.
    EntryCount,           -- Size of Entries array.
    TabSliderTrig,        -- Trigger to scroll tab buttons with slider
    TabButtonTrigs = {},  -- Triggers to update text when tab buttons are clicked
    TabPosOffset   = 0,   -- How much the position/width of tabs are adjusted to simulate scrolling
    TabSkip        = 0,   -- Number of tabs scrolled past with slider, starting from 0.
    
    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}

        -- Init empty table properties --
        if (o.Entries == nil) then o.Entries = {} end
        if (o.TabButtonTrigs == nil) then o.TabButtonTrigs = {} end

        -- Init default params and methods --
        setmetatable(o, {__index = self})
        o.EntryCount = #o.Entries

        -- Init supatable functionality --
        local tbl = table2.supaTable:new(o)
        
        -- Create Frame --
        tbl.Frame = BlzCreateFrame("TabMenu", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        BlzFrameSetAbsPoint(tbl.Frame, FRAMEPOINT_TOPLEFT, 0.02, 0.553)

        -- Init all frame children --
        tbl:updateCloseButtonPos()
        tbl:updateTabLabels()
        tbl:updateTabCount()
        tbl:updateTabSlider()
        tbl:initTabSliderTrig()
        tbl:initTabButtonTrigs()

        -- supaTable: Auto-update frame --
        tbl:watchProp(function(t,k,v)
            getmetatable(tbl).__index.EntryCount = #tbl.Entries --Set read-only prop (supaTable)
            tbl:updateTabLabels()
            tbl:updateTabCount()
            tbl:updateTabSlider()
            tbl:updateText()
        end, "Entries", true)

        tbl:watchProp(function(t,k,v)
            tbl:updateCloseButtonPos()
        end, "BoardMode", false)

        -- supaTable: Set read-only properties --
        tbl:setReadOnly(true, "Frame")
        tbl:setReadOnly(true, "ButtonCurrent")
        tbl:setReadOnly(true, "EntryCurrent")
        tbl:setReadOnly(true, "EntryCount")
        tbl:setReadOnly(true, "TabSliderTrig")
        tbl:setReadOnly(true, "TabButtonTrigs")
        tbl:setReadOnly(true, "TabPosOffset")
        tbl:setReadOnly(true, "TabSkip")

        -- Return --
        return tbl
    end,

    --<< PRIVATE METHODS >>--
    --=================================================--
    -- tabMenu:updateCloseButtonPos()                  --
    --                                                 --
    -- Positions CloseButton, TabBar, and TabBarSlider --
    -- to be compatible with BoardMode.                --
    --=================================================--
    updateCloseButtonPos = function(self)
        local closeButton = BlzFrameGetChild(self.Frame, 1)
        local tabBar      = BlzFrameGetChild(self.Frame, 2)
        local tabSlider   = BlzFrameGetChild(self.Frame, 3)

        local closeButtonY = -constTabMenu.borderSize
        local tabBarY      = -constTabMenu.borderSize
        local tabSliderY   = -constTabMenu.borderSize - (constTabMenu.menuSize * constTabMenu.tabBarHeight)

        if (self.BoardMode == false) then
            local closeButtonX = (constTabMenu.menuSize * constTabMenu.tabBarWidth) + constTabMenu.borderSize
            local tabBarX      = constTabMenu.borderSize
            local tabSliderX   = tabBarX
            BlzFrameSetPoint(closeButton, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, closeButtonX, closeButtonY)
            BlzFrameSetPoint(tabBar, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, tabBarX, tabBarY)
            BlzFrameSetPoint(tabSlider, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, tabSliderX, tabSliderY)
        else
            local closeButtonX = constTabMenu.borderSize
            local tabBarX      = (constTabMenu.menuSize * constTabMenu.closeButtonWidth) + constTabMenu.borderSize
            local tabSliderX   = tabBarX
            BlzFrameSetPoint(closeButton, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, closeButtonX, closeButtonY)
            BlzFrameSetPoint(tabBar, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, tabBarX, tabBarY)
            BlzFrameSetPoint(tabSlider, FRAMEPOINT_TOPLEFT, self.Frame, FRAMEPOINT_TOPLEFT, tabSliderX, tabSliderY)
        end
    end,

    --==============================================--
    -- tabMenu:updateTabLabels()                    --
    --                                              --
    -- Updates tab labels to corresponding entries. --
    --==============================================--
    updateTabLabels = function(self)
        local tabBar = BlzFrameGetChild(self.Frame, 2)
        for i=1, math.min(5, self.EntryCount) do
            local tab = BlzFrameGetChild(tabBar, i-1)
            BlzFrameSetText(tab, self.Entries[self.TabSkip+i].Label)
        end
    end,

    --=================================================--
    -- tabMenu:updateTabCount()                        --
    --                                                 --
    -- If less than 5 entries, hides some tab buttons. --
    --=================================================--
    updateTabCount = function(self)
        local tabBar = BlzFrameGetChild(self.Frame, 2)

        for i=1, math.min(5, self.EntryCount) do
            local tab = BlzFrameGetChild(tabBar, i-1)
            BlzFrameSetVisible(tab, true)
        end

        for i=(self.EntryCount+1), 5 do
            local tab = BlzFrameGetChild(tabBar, i-1)
            BlzFrameSetVisible(tab, false)
        end
    end,

    --==========================================--
    -- tabMenu:updateTabSlider()                --
    --                                          --
    -- Hides tab slider if less than 4 buttons. --
    --==========================================--
    updateTabSlider = function(self)
        local tabSlider = BlzFrameGetChild(self.Frame, 3)
        if (self.EntryCount < 5) then
            BlzFrameSetVisible(tabSlider, false)
        else
            BlzFrameSetVisible(tabSlider, true)
        end
    end,

    --================================================--
    -- tabMenu:updateText()                           --
    --                                                --
    -- Updates text to show currently selected Entry. --
    --================================================--
    updateText = function(self)   
        if (self.EntryCurrent == nil) then return end

        local textTitle     = BlzFrameGetChild(BlzFrameGetChild(self.Frame, 4), 1)
        local textLeftBody  = BlzFrameGetChild(BlzFrameGetChild(self.Frame, 5), 1)
        local textRightBody = BlzFrameGetChild(BlzFrameGetChild(self.Frame, 6), 1)

        BlzFrameSetText(textTitle, self.Entries[self.EntryCurrent].Title)
        BlzFrameSetText(textLeftBody, self.Entries[self.EntryCurrent].Desc1)
        BlzFrameSetText(textRightBody, self.Entries[self.EntryCurrent].Desc2)
    end,

    --=========================================================--
    -- tabMenu:initTabSliderTrig()                             --
    --                                                         --
    -- Updates trigger for scrolling through tabs with slider. --
    --=========================================================--
    initTabSliderTrig = function(self)
        local tabBar    = BlzFrameGetChild(self.Frame, 2)
        local tabSlider = BlzFrameGetChild(self.Frame, 3)
        
        local tab0 = BlzFrameGetChild(tabBar, 0)
        local tab1 = BlzFrameGetChild(tabBar, 1)
        local tab2 = BlzFrameGetChild(tabBar, 2)
        local tab3 = BlzFrameGetChild(tabBar, 3)
        local tab4 = BlzFrameGetChild(tabBar, 4)

        local tabWidth  = constTabMenu.menuSize * constTabMenu.tabWidth
        local tabHeight = constTabMenu.menuSize * constTabMenu.tabHeight
        
        -- Update tabs every time slider changes --
        local newTrig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(newTrig, tabSlider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
        TriggerAddAction(newTrig, function()
            -- Slider does nothing if 4 or less tabs --
            if (self.EntryCount < 5) then return end

            -- Update read-only properties (supaTable) --
            local oldTabSkip = self.TabSkip
            local sliderValue = BlzGetTriggerFrameValue()
            local sliderRangePerTab = constTabMenu.sliderRange / (self.EntryCount - 4)
            local actualTable = getmetatable(self).__index
            actualTable.TabPosOffset = tabWidth * ((sliderValue % sliderRangePerTab) / sliderRangePerTab)
            actualTable.TabSkip = math.floor(sliderValue / sliderRangePerTab)

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
            
            -- If scrolled to a new button, update tab labels --
            if (self.TabSkip ~= oldTabSkip) then
                self:updateTabLabels()
            end
        end)

        -- Clean up old trigger and replace it with new trigger --
        if (self.TabSliderTrig ~= nil) then
            DestroyTrigger(self.TabSliderTrig)
            self.TabSliderTrig = nil
        end
        self.TabSliderTrig = newTrig
    end,

    
    --================================================================--
    -- tabMenu:initTabButtonTrigs()                                   --
    --                                                                --
    -- Update triggers that change text when tab buttons are clicked. --
    --================================================================--
    initTabButtonTrigs = function(self)
        local tabBar = BlzFrameGetChild(self.Frame, 2)
        for i=1, 5 do

            -- Clean up old trigger --
            if (self.TabButtonTrigs[i] ~= nil) then
                DestroyTrigger(self.TabButtonTrigs[i])
                self.TabButtonTrigs[i] = nil
            end

            -- Create new trigger that runs on button click --
            local tabButton = BlzFrameGetChild(tabBar, i-1)
            self.TabButtonTrigs[i] = CreateTrigger()
            BlzTriggerRegisterFrameEvent(self.TabButtonTrigs[i], tabButton, FRAMEEVENT_CONTROL_CLICK)
            TriggerAddAction(self.TabButtonTrigs[i], function()

                -- Update read-only properties (supaTable) --
                local actualTable = getmetatable(self).__index
                actualTable.ButtonCurrent = i-1
                actualTable.EntryCurrent = self.TabSkip + i

                -- Display text for currently selected entry --
                self:updateText()
            end)
        end
    end,
    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--=============--
return libTabMenu
--=============--
