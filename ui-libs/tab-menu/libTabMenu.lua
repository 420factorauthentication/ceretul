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
    MenuSize   = 0.5,   -- Side length of square menu frame. Doesn't include borders. In scale of [0.8:0.6]
    BorderSize = 0.05,  -- Width of one border edge. In scale of [0.8:0.6]
    Entries    = {},    -- tabMenuEntry class objects

    --== Read-Only ==--
    Frame,                -- Framehandle for main parent frame
    TabSliderTrig,        -- Trigger to scroll tab buttons with slider
    TabButtonTrigs = {},  -- Triggers to update text when tab buttons are clicked
    TabSkip        = 0,   -- Number of leftmost tab in current slider position
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
        tbl:updateFrameSizes()
        tbl:updateTabBar()

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
    --=============================================================--
    -- tabMenu:updateTabBar()                                      --
    --                                                             --
    -- Creates a TabBar button for each entry.                     --
    -- Updates TabBar button labels and triggers.                  --
    -- If currently selected entry is updated, updates text boxes. --
    --=============================================================--
    updateTabBar = function(self)
        local tabBar = BlzFrameGetChild(self.Frame, 2)
        local textTitle = BlzFrameGetChild( BlzFrameGetChild(self.Frame,4) , 1)
        local textLeftBody = BlzFrameGetChild( BlzFrameGetChild(self.Frame,5) , 1)
        local textRightBody = BlzFrameGetChild( BlzFrameGetChild(self.Frame,6) , 1)

        local tabWidth = self.MenuSize * constTabMenu.tabWidth
        local tabHeight = self.MenuSize * constTabMenu.tabHeight
        local existingTabCount = BlzFrameGetChildrenCount(tabBar)
        local newTabPosition = 0

        -- Update existing tab button labels --
        for i=1, existingTabCount do
            local tab = BlzFrameGetChild(tabBar, i-1)
            BlzFrameSetText(tab, self.Entries[i].Label)
        end

        -- Dont create new tab buttons if already 5 --
        if (existingTabCount >= 5) then return end

        local createNewTab = function(width, pos, label)
            local newTab = BlzCreateFrame("NewTabMenuTab", tabBar, 0, 0)
            local textTab = BlzFrameGetChild(newTab, 0)
            BlzFrameSetSize(newTab, width, tabHeight)
            BlzFrameSetPoint(newTab, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, pos, 0)
            BlzFrameSetText(textTab, label)
            existingTabCount = existingTabCount + 1
            newTabPosition = newTabPosition + width
        end

        -- Create Tab Button 0 if needed --
        if (existingTabCount == 0) then
            createNewTab((tabWidth - self.TabPosOffset), newTabPosition, self.Entries[1].Label) end

        -- Create Tab Buttons 1-4 if needed --
        for i=(existingTabCount+1), 5 do
            createNewTab(tabWidth, newTabPosition, self.Entries[i].Label) end
    end,

    --=============================================--
    -- tabMenu:updateTabBarSlider()                --
    --                                             --
    -- Updates the trigger for the tab bar slider. --
    --=============================================--
    updateTabBarSlider = function(self)
        local tabBar = BlzFrameGetChild(self.Frame, 2)
        local tabSlider = BlzFrameGetChild(self.Frame, 3)
        
        -- Create new trigger --
        self.TabSliderTrig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(self.TabSliderTrig, tabSlider, FRAMEEVENT_SLIDER_VALUE_CHANGED)
        TriggerAddAction(self.TabSliderTrig, function()

            -- Slider does nothing if 4 or less tabs --
            local tabCount = BlzFrameGetChildrenCount(tabBar)
            if (tabCount < 5) then return end

            -- Quick maffs --
            local tabWidth = self.MenuSize * constTabMenu.tabWidth
            local tabHeight = self.MenuSize * constTabMenu.tabHeight
            local sliderValue = BlzGetTriggerFrameValue()
            local sliderRangePerTab = constTabMenu.sliderRange / (tabCount - 4)

            -- Manually set read-only values (supaTable) --
            getmetatable(self).__index.TabPosOffset = tabWidth * ((sliderValue % sliderRangePerTab) / sliderRangePerTab)
            getmetatable(self).__index.TabSkip = math.floor(sliderValue / sliderRangePerTab)

            -- Adjust width and position of tabs to simulate scrolling --
            if (tabCount > 0) then
                local tab0 = BlzFrameGetChild(tabBar, 0)
                BlzFrameSetSize(tab0, (tabWidth - self.TabPosOffset), tabHeight)
            end

            if (tabCount >= 5) then
                local tab4 = BlzFrameGetChild(tabBar, 4)
                BlzFrameSetSize(tab4, self.TabPosOffset, tabHeight)
            end

            for i=2, tabCount do
                local tab = BlzFrameGetChild(tabBar, i-1)
                BlzFrameSetPoint(tab, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, (self.TabPosOffset + (tabWidth * (i-2))), 0)
            end

            -- Set tab labels --
            for i=1, tabCount do
                local tab = BlzFrameGetChild(tabBar, i-1)
                local textTab = BlzFrameGetChild(tab, 0)
                local tabNum = self.TabSkip + (i-1)
                BlzFrameSetText(textTab, self.Entries[tabNum].Label)
            end
        end)

        -- Clean up old trigger and replace it with new trigger --
        if (self.TabSliderTrig ~= nil) then
            DestroyTrigger(self.TabSliderTrig)
            self.TabSliderTrig = nil
        end
        self.TabSliderTrig = sliderTrig
    end,



    --===============================================--
    -- tabMenu:updateFrameSizes()                    --
    --                                               --
    -- Updates all frame children to match MenuSize. --
    --===============================================--


    },{

    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--=============--
return libTabMenu
--=============--
