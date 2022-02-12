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

    --== Auto-Update Functionality On Change ==--
    Entries   = {},     -- tabMenuEntry class objects
    BoardMode = false,  -- If game has a leaderboard, set this to true, to avoid blocking buttons.

    --== Read-Only ==--
    Frame,                -- Framehandle for main parent frame
    ButtonCurrent,        -- Number of currently clicked tab button (0-4). Up to 5 tab buttons visible at one time.
    EntryCurrent,         -- Entries array index of currently clicked tab button, starting from 1.
    EntryCount,           -- Size of Entries array. (not the supaTable proxy)
    CloseButtonTrig,      -- Trigger to hide frame when close button is clicked
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

        -- Init default vars and methods --
        o.EntryCount = #o.Entries
        o.Frame = BlzCreateFrame("TabMenu", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        BlzFrameSetAbsPoint(o.Frame, FRAMEPOINT_TOPLEFT, 0.02, 0.553)
        setmetatable(o, {__index = self})

        -- This class is a supaTable --
        local tbl = table2.supaTable:new(o)

        -- Set read-only properties (supaTable) --
        tbl:setReadOnly(true, "Frame")
        tbl:setReadOnly(true, "ButtonCurrent")
        tbl:setReadOnly(true, "EntryCurrent")
        tbl:setReadOnly(true, "EntryCount")
        tbl:setReadOnly(true, "TabSliderTrig")
        tbl:setReadOnly(true, "TabButtonTrigs")
        tbl:setReadOnly(true, "TabPosOffset")
        tbl:setReadOnly(true, "TabSkip")

        -- Auto-update frame (supaTable) --
        tbl:watchProp(function(t,k,v)
            tbl:sortEntries()

            -- Update EntryCount, using actual Entries table (not supaTable proxy) --
            getmetatable(tbl).__index.EntryCount = #getmetatable(tbl.Entries).__index
            print(tbl.EntryCount)
            
            tbl:updateTabLabels()
            tbl:updateTabCount()
            tbl:updateTabSlider()
            tbl:updateText()
        end, "Entries", true)

        tbl:watchProp(function(t,k,v)
            tbl:updateCloseButtonPos()
        end, "BoardMode", false)

        -- Main --
        tbl:updateCloseButtonPos()
        tbl:updateTabLabels()
        tbl:updateTabCount()
        tbl:updateTabSlider()
        tbl:initTabSliderTrig()
        tbl:initTabButtonTrigs()
        tbl:initCloseButtonTrig()

        -- Return --
        return tbl
    end,

    --<< PRIVATE METHODS >>--
    --====================================--
    -- tabMenu:sortEntries()              --
    --                                    --
    -- Formats the Entries table so that  --
    -- keys are integers starting from 1. --
    --====================================--
    sortEntries = function(self)
        -- Actual Entries, not supaTable proxy --
        local tblEntries = getmetatable(self.Entries).__index  

        local newTblEntries = {}
        for k, v in pairs(tblEntries) do
            table.insert(newTblEntries, v)
        end

        -- Set actual Entries --
        getmetatable(self.Entries).__index = newTblEntries
    end,
    
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
        local tabWidth  = constTabMenu.menuSize * constTabMenu.tabWidth
        local tabHeight = constTabMenu.menuSize * constTabMenu.tabHeight

        for i=1, math.min(5, self.EntryCount) do
            local tab = BlzFrameGetChild(tabBar, i-1)
            BlzFrameSetVisible(tab, true)
        end

        for i=(self.EntryCount+1), 5 do
            local tab = BlzFrameGetChild(tabBar, i-1)
            BlzFrameSetVisible(tab, false)
        end
    end,

    --=========================================--
    -- tabMenu:updateTabSlider()               --
    --                                         --
    -- If less than 5 entries, hide tab slider --
    -- and reset tab width and position.       --
    --=========================================--
    updateTabSlider = function(self)
        local tabBar    = BlzFrameGetChild(self.Frame, 2)
        local tabSlider = BlzFrameGetChild(self.Frame, 3)
        local tabWidth  = constTabMenu.menuSize * constTabMenu.tabWidth
        local tabHeight = constTabMenu.menuSize * constTabMenu.tabHeight

        if (self.EntryCount < 5) then
            BlzFrameSetVisible(tabSlider, false)
            BlzFrameSetValue(tabSlider, 0)

            for i=1, 4 do
                local tab = BlzFrameGetChild(tabBar, i-1)
                local tabPosX = tabWidth * (i-1)
                BlzFrameSetSize(tab, tabWidth, tabHeight)
                BlzFrameSetPoint(tab, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, tabPosX, 0)
            end

            local tab4 = BlzFrameGetChild(tabBar, 4)
            local tabPosX4 = tabWidth * 4
            BlzFrameSetSize(tab4, 0, tabHeight)
            BlzFrameSetPoint(tab4, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, tabPosX4, 0)
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
        local tbl = getmetatable(self).__index  --Used to set read-only props (supaTable)

        local tabBar    = BlzFrameGetChild(self.Frame, 2)
        local tabSlider = BlzFrameGetChild(self.Frame, 3)
        
        local tab0 = BlzFrameGetChild(tabBar, 0)
        local tab1 = BlzFrameGetChild(tabBar, 1)
        local tab2 = BlzFrameGetChild(tabBar, 2)
        local tab3 = BlzFrameGetChild(tabBar, 3)
        local tab4 = BlzFrameGetChild(tabBar, 4)

        local tabHeight = constTabMenu.menuSize * constTabMenu.tabHeight
        local tabWidth  = constTabMenu.menuSize * constTabMenu.tabWidth
        local minWidth  = 0.02
        
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
            tbl.TabPosOffset = tabWidth * ((sliderValue % sliderRangePerTab) / sliderRangePerTab)
            tbl.TabSkip = math.floor(sliderValue / sliderRangePerTab)

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

            --- Hide tabs if too small, to avoid display quirks --
            if (tabWidth0 < minWidth) then
                BlzFrameSetVisible(tab0, false)
            else
                BlzFrameSetVisible(tab0, true)
            end

            if (tabWidth4 < minWidth) then
                BlzFrameSetVisible(tab4, false)
            else
                BlzFrameSetVisible(tab4, true)
            end
            
            -- If scrolled to a new button, update tab labels --
            if (self.TabSkip ~= oldTabSkip) then
                self:updateTabLabels()
            end
        end)

        -- Clean up old trigger and replace it with new trigger --
        if (self.TabSliderTrig ~= nil) then
            DestroyTrigger(self.TabSliderTrig) end
        tbl.TabSliderTrig = newTrig
    end,

    
    --================================================================--
    -- tabMenu:initTabButtonTrigs()                                   --
    --                                                                --
    -- Update triggers that change text when tab buttons are clicked. --
    --================================================================--
    initTabButtonTrigs = function(self)
        local tabBar = BlzFrameGetChild(self.Frame, 2)

        -- Used to set read-only props (supaTable) --
        local tbl = getmetatable(self).__index
        local tblTrigs = getmetatable(self.TabButtonTrigs).__index
        
        for i=1, 5 do
            -- Clean up old trigger --
            if (self.TabButtonTrigs[i] ~= nil) then
                DestroyTrigger(self.TabButtonTrigs[i])
            end

            -- Create new trigger that runs on button click --
            local tabButton = BlzFrameGetChild(tabBar, i-1)
            tblTrigs[i] = CreateTrigger()
            BlzTriggerRegisterFrameEvent(self.TabButtonTrigs[i], tabButton, FRAMEEVENT_CONTROL_CLICK)
            TriggerAddAction(self.TabButtonTrigs[i], function()

                -- Update current selection --
                tbl.ButtonCurrent = i-1
                tbl.EntryCurrent = self.TabSkip + i
                self:updateText()
            end)
        end
    end,

    --===============================================================--
    -- tabMenu:initCloseButtonTrig()                                 --
    --                                                               --
    -- Update trigger that hides frame when close button is clicked. --
    --===============================================================--
    initCloseButtonTrig = function(self)
        local closeButton = BlzFrameGetChild(self.Frame, 1)
        local newTrig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(newTrig, closeButton, FRAMEEVENT_CONTROL_CLICK)
        TriggerAddAction(newTrig, function()
            BlzFrameSetVisible(self.Frame, false)
        end)

        -- Clean up old trigger and replace it with new trigger --
        if (self.CloseButtonTrig ~= nil) then
            DestroyTrigger(self.CloseButtonTrig) end
        getmetatable(self).__index.CloseButtonTrig = newTrig  --Set read-only prop (supaTable)
    end,
    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--=============--
return libTabMenu
--=============--
