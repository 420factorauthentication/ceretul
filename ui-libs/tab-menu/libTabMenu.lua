--=================--
local libTabMenu = {}
--=================--

-- < Modules > --
local table2 = require "table2"



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

    --== Frame Dimensions (in scale of 0.8:0.6) ==--
    MenuSize   = 0.5,   -- Side length of square menu frame. Doesn't include borders.
    BorderSize = 0.05,  -- Width of one border edge.

    --== Read-Only ==--
    Frame,           -- Framehandle for main parent frame
    Entries   = {},  -- tabMenuEntry class objects
    CurrEntry = 0,   -- Currently clicked tab number
    SliderPos = 0,   -- Number of leftmost tab in current slider position

    --== Read-Only Constants: Ratios of MenuSize ==--
    CloseButtonSizeFactor = (1/16),
    TabBarWidthFactor     = (15/16),
    TabBarHeightFactor    = (1/16),
    TabWidthFactor        = ((1/4) * (15/16)),
    TabHeightFactor       = (1/16),
    SectionWidthFactor    = (15/32),
    TitleHeightFactor     = (1/16),
    LeftBodyHeightFactor  = (12/16),
    RightBodyHeightFactor = (13/16),
    VertPaddingFactor     = (1/16),
    HorizPaddingFactor    = (1/32),

    --== Read-Only Constants: Tab Bar Slider ==--
    TabBarSliderMin = 0,
    TabBarSliderMax = 100,

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        if (o.Entries == nil) then o.Instances = {} end
        setmetatable(o, {__index = self})
        local tbl = table2.supaTable:new(o)

        -- Set read only properties --
        tbl:setReadOnly(true, "Frame")
        tbl:setReadOnly(true, "Entries")
        tbl:setReadOnly(true, "CurrEntry")
        tbl:setReadOnly(true, "SliderPos")
        
        tbl:setReadOnly(true, "CloseButtonSizeFactor")
        tbl:setReadOnly(true, "TabBarWidthFactor")
        tbl:setReadOnly(true, "TabBarHeightFactor")
        tbl:setReadOnly(true, "TabWidthFactor")
        tbl:setReadOnly(true, "TabHeightFactor")
        tbl:setReadOnly(true, "SectionWidthFactor")
        tbl:setReadOnly(true, "TitleHeightFactor")
        tbl:setReadOnly(true, "LeftBodyHeightFactor")
        tbl:setReadOnly(true, "RightBodyHeightFactor")
        tbl:setReadOnly(true, "VertPaddingFactor")
        tbl:setReadOnly(true, "HorizPaddingFactor")
        
        tbl:setReadOnly(true, "TabBarSliderMin")
        tbl:setReadOnly(true, "TabBarSliderMax")
        
        -- Create Frame --
        tbl.Frame = BlzCreateFrame("TabMenu", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        local tabMenu = libTabMenu.tabMenu:new({Frame = framehandle})
        BlzFrameSetAbsPoint(framehandle, FRAMEPOINT_TOPLEFT, 0.02, 0.553)

        local tabBar = BlzFrameGetChild(tbl.Frame, 2)
        local tab0 = BlzFrameGetChild(tabBar, 0)
        local tab1 = BlzFrameGetChild(tabBar, 1)
        local tab2 = BlzFrameGetChild(tabBar, 2)
        local tab3 = BlzFrameGetChild(tabBar, 3)
        local tab4 = BlzFrameGetChild(tabBar, 4)

        local textTab0 = BlzFrameGetChild(tab0, 0)
        local textTab1 = BlzFrameGetChild(tab1, 0)
        local textTab2 = BlzFrameGetChild(tab2, 0)
        local textTab3 = BlzFrameGetChild(tab3, 0)
        local textTab4 = BlzFrameGetChild(tab4, 0)

        local textTitle = BlzFrameGetChild( BlzFrameGetChild(tbl.Frame,4) , 1)
        local textLeftBody = BlzFrameGetChild( BlzFrameGetChild(tbl.Frame,5) , 1)
        local textRightBody = BlzFrameGetChild( BlzFrameGetChild(tbl.Frame,6) , 1)

        -- Init tab labels --
        BlzFrameSetText(textTab0, tbl.Entries[1].Label)
        BlzFrameSetText(textTab1, tbl.Entries[2].Label)
        BlzFrameSetText(textTab2, tbl.Entries[3].Label)
        BlzFrameSetText(textTab3, tbl.Entries[4].Label)
        BlzFrameSetText(textTab4, tbl.Entries[5].Label)

        -- Functionality: Tab Bar Slider --
        local sliderTrig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(sliderTrig, framehandle, FRAMEEVENT_SLIDER_VALUE_CHANGED)
        TriggerAddAction(sliderTrig, function()

            -- Tab Bar can fit 4 tabs. Don't adjust tab bar if 4 or less tabs. --
            if (#tbl.Entries < 5) then return end

            -- Quick maffs --
            local sliderValue = BlzGetTriggerFrameValue()
            local sliderRange = math.abs(tbl.TabBarSliderMax - tbl.TabBarSliderMin)
            local sliderRangePerTab = sliderRange / (#tbl.Entries - 4)
            local tabWidth = tbl.MenuSize * tbl.TabWidthFactor
            local tabHeight = tbl.MenuSize * tbl.TabHeightFactor
            local tabOffset = tabWidth * ((sliderValue % sliderRangePerTab) / sliderRangePerTab)
            tbl.sliderPos = math.floor(sliderValue / sliderRangePerTab)

            -- Adjust tabs width and position to simulate scrolling --
            BlzFrameSetSize(tab0, (tabWidth - tabOffset), tabHeight)
            BlzFrameSetSize(tab4, (tabWidth - tabOffset), tabHeight)
            BlzFrameSetPoint(tab1, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, (tabOffset + (tabWidth * 0)), 0)
            BlzFrameSetPoint(tab2, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, (tabOffset + (tabWidth * 1)), 0)
            BlzFrameSetPoint(tab3, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, (tabOffset + (tabWidth * 2)), 0)
            BlzFrameSetPoint(tab4, FRAMEPOINT_TOPLEFT, tabBar, FRAMEPOINT_TOPLEFT, (tabOffset + (tabWidth * 3)), 0)

            -- Set tab labels --
            BlzFrameSetText(textTab0, tbl.Entries[tbl.sliderPos + 1].Label)
            BlzFrameSetText(textTab1, tbl.Entries[tbl.sliderPos + 2].Label)
            BlzFrameSetText(textTab2, tbl.Entries[tbl.sliderPos + 3].Label)
            BlzFrameSetText(textTab3, tbl.Entries[tbl.sliderPos + 4].Label)
            BlzFrameSetText(textTab4, tbl.Entries[tbl.sliderPos + 5].Label)
        end)

        -- Functionality: Tab Buttons --
        

        -- Init: select first tab --
        BlzFrameClick(tab0)

        -- Return --
        return tbl
    end,

    --========================================--
    -- tabMenu:newEntry()                     --
    --                                        --
    -- Inits a new TabMenuEntry class object. --
    -- Links it to a new button at the top.   --
    --========================================--
    newEntry = function()
        local newTabMenuEntry = libTabMenu.tabMenuEntry:new()
        local tabButton = BlzCreateFrame("NewTabMenuTab", tbl.Frame, 0, 0)
    end
    },{

    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--=========--
return libTabMenu
--=========--
