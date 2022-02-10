--=============--
local libCCG = {}
--=============--

-- < Modules > --
local table2 = require "table2"
local libRTS = require "libRTS"

-- < References > --
local constCCG = require "constCCG"



--======================================================================--
-- class card                                                           --
-- An object that defines a new card and it's default stats.            --
-- Changing properties here affects future card instances, not current. --
--======================================================================--
libCCG.card = setmetatable({
    Name = "New Card",

    --== Read-Only ==--
    IsCard    = true,  -- Used for error checking.
    Instances = {},    -- All active libCCG.cardInstances of this card.

    --== Categorization ==--
    Class,    -- constCCG.cardClass
    Faction,  -- constCCG.faction

    --== Art ==--
    BackBgPath,   -- Path to texture for back of card.
    FrontBgPath,  -- Path to texture for front of card.
    CardArtPath,  -- Path to texture for picture at top of card front.
    TitleText,    -- Title text at top of card.
    DescText,     -- Description text at bottom of card.

    --== Stats ==--
    DefaultReqs    = {},  -- libRTS.statInstance
    DefaultCosts   = {},  -- libRTS.statInstance
    DefaultEffects = {},  -- libRTS.statInstance
    
    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}

        -- Init empty table properties --
        if (o.Instances == nil) then o.Instances = {} end
        if (o.DefaultReqs == nil) then o.DefaultReqs = {} end
        if (o.DefaultCosts == nil) then o.DefaultCosts = {} end
        if (o.DefaultEffects == nil) then o.DefaultEffects = {} end

        -- init default vars and methods --
        setmetatable(o, {__index = self})

        -- This class is a supaTable --
        local tbl = table2.supaTable:new(o)

        -- supaTable: Set read-only properties --
        tbl:setReadOnly(true, "IsCard")
        tbl:setReadOnly(true, "Instances")

        -- supaTable: Auto-update War3 Frame art in every instance --
        tbl:watchProp(function(t,k,v)
            for x, d in pairs(t.Instances) do
                d:setBackBg(v) end
        end, "BackBgPath", false)

        tbl:watchProp(function(t,k,v)
            for x, d in pairs(t.Instances) do
                d:setFrontBg(v) end
        end, "FrontBgPath", false)

        tbl:watchProp(function(t,k,v)
            for x, d in pairs(t.Instances) do
                d:setCardArt(v) end
        end, "CardArtPath", false)

        tbl:watchProp(function(t,k,v)
            for x, d in pairs(t.Instances) do
                d:setTitleText(v) end
        end, "TitleText", false)

        tbl:watchProp(function(t,k,v)
            for x, d in pairs(t.Instances) do
                d:setDescText(v) end
        end, "DescText", false)

        -- Return --
        return tbl
    end,

    --=======================================--
    -- card:addToDeck()                      --
    --                                       --
    -- Inserts a cardInstance into the deck. --
    --=======================================--
    addToDeck = function(self)
        local newInst = libCCG.cardInstance:new(self)
        newInst:setState(constCCG.cardState.deck)
    end,
    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--======================================================= --
-- class cardInstance                                     --
-- An active instance of a card.                          --
-- Changing properties here affects this single instance. --
-- Automatically updates UI when properties are changed.  --
-- NOTE: Pass a libCCG.card object to the constructor.    --
--======================================================= --
libCCG.cardInstance = setmetatable({
    Name = "New Card Instance",

    --== Read-Only ==--
    Frame,           -- The active War3 framehandle for this cardInstance
    ZoomFrame,       -- Framehandle for the enlarged card that shows on mouseover
    MouseEnterTrig,  -- Trigger to show enlarged card on mouseover
    MouseLeaveTrig,  -- Trigger to hide enlarged card on mouseover

    --== Default Stats ==--
    Card,  -- The libCCG.card instance that this was created from

    --== Current Stats ==--
    CurrState,         -- constCCG.cardState
    CurrReqs    = {},  -- libRTS.statInstance
    CurrCosts   = {},  -- libRTS.statInstance
    CurrEffects = {},  -- libRTS.statInstance

    --=====================--
    -- Constructor         --
    --   card: libCCG.card --
    --=====================--
    new = function(self, card)
        if (card.IsCard ~= true) then
            print("error: libCCG.cardInstance constructor expects libCCG.card") end

        -- init default vars and methods --
        local o = setmetatable({
            Card        = card,
            CurrReqs    = card.DefaultReqs,
            CurrCosts   = card.DefaultCosts,
            CurrEffects = card.DefaultEffects
        }, {__index = self})

        -- This class is a supaTable --
        local tbl = table2.supaTable:new(o)
        
        -- Create and position War3 Frames --
        local createContext = #(gCCG.cardInstances)

        tbl.Frame = BlzCreateFrame("Card", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, createContext)
        BlzFrameSetAbsPoint(tbl.Frame, FRAMEPOINT_CENTER, (0.075 + (constCCG.cardState.handSlot5 * 0.065)), 0.09) -- todo: card position setup
        BlzFrameSetLevel(tbl.Frame, 3)

        tbl.ZoomFrame = BlzCreateFrame("CardZoom", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, createContext)
        BlzFrameSetAbsPoint(tbl.ZoomFrame, FRAMEPOINT_CENTER, (0.075 + (constCCG.cardState.handSlot5 * 0.065)), 0.135) -- todo: card position setup
        BlzFrameSetLevel(tbl.ZoomFrame, 2)
        BlzFrameSetVisible(tbl.ZoomFrame, false)

        -- Init War3 Frame art --
        tbl:setBackBg()
        tbl:setFrontBg()
        tbl:setCardArt()
        tbl:setTitleText()
        tbl:setDescText()

        -- Setup mouse interactions --
        local buttonChild = BlzFrameGetChild(tbl.Frame, 7)

        tbl.MouseEnterTrig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(tbl.MouseEnterTrig, buttonChild, FRAMEEVENT_MOUSE_ENTER)
        TriggerAddAction(tbl.MouseEnterTrig, function()
            if ((gCCG.isMouseDown == false) or (gCCG.currHoveredCardInst == nil)) then
                tbl:hideCard()
                tbl:showZoom()
                if (gCCG.currHoveredCardInst == tbl) then
                    return
                elseif (gCCG.currHoveredCardInst ~= nil) then
                    gCCG.currHoveredCardInst:showCard()
                    gCCG.currHoveredCardInst:hideZoom()
                end
                gCCG.currHoveredCardInst = tbl
            end
        end)

        tbl.MouseLeaveTrig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(tbl.MouseLeaveTrig, buttonChild, FRAMEEVENT_MOUSE_LEAVE)
        TriggerAddAction(tbl.MouseLeaveTrig, function()
            if (gCCG.isMouseDown == false) then
                tbl:showCard()
                tbl:hideZoom()
                if (gCCG.currHoveredCardInst == tbl) then
                    gCCG.currHoveredCardInst = nil
                end
            end
        end)

        -- Return --
        table.insert(getmetatable(card).__index.Instances, tbl)
        table.insert(gCCG.cardInstances, tbl)
        return tbl
    end,

    --=============================--
    -- cardInstance:destroy()      --
    --                             --
    -- Destroys this cardInstance. --
    --=============================--
    destroy = function(self)
        BlzDestroyFrame(self.Frame)
        BlzDestroyFrame(self.ZoomFrame)

        for k, v in pairs(self.Card.Instances) do
            if (v == self) then
                self.Card.Instances[k] = nil
                break
            end
        end

        for k, v in pairs(gCCG.cardInstances) do
            if (v == self) then
                gCCG.cardInstances[k] = nil
                break
            end
        end
    end,

    --=============================================--
    -- cardInstance:setState()                     --
    --   state: constCCG.cardState (int)           --
    --                                             --
    -- Sets location (deck, hand, graveyard, etc.) --
    --=============================================--
    setState = function(self, state)
        -- todo: card position setup --
    end,

    --=================================================--
    -- cardInstance:showZoom()                         --
    --                                                 --
    -- Shows an enlarged frame above this cards frame. --
    --=================================================--
    showZoom = function(self)
        BlzFrameSetVisible(self.ZoomFrame, true)
    end,

    --==============================--
    -- cardInstance:hideZoom()      --
    --                              --
    -- Hides this cards zoom frame. --
    --==============================--
    hideZoom = function(self)
        BlzFrameSetVisible(self.ZoomFrame, false)
    end,

    --=========================--
    -- cardInstance:showCard() --
    --                         --
    -- Shows this cards frame. --
    --=========================--
    showCard = function(self)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 0), true)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 1), true)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 2), true)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 3), true)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 4), true)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 5), true)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 6), true)
    end,

    --=========================--
    -- cardInstance:hideCard() --
    --                         --
    -- Hides this cards frame. --
    --=========================--
    hideCard = function(self)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 0), false)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 1), false)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 2), false)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 3), false)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 4), false)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 5), false)
        BlzFrameSetVisible(BlzFrameGetChild(self.Frame, 6), false)
    end,

    --<< PRIVATE METHODS >>--
    --==========================--
    -- cardInstance:setBackBg() --
    --==========================--
    setBackBg = function(self, path)
        path = path or self.Card.BackBgPath
        BlzFrameSetTexture(BlzFrameGetChild(self.Frame, 0), path, 0, true)
        BlzFrameSetTexture(BlzFrameGetChild(self.ZoomFrame, 0), path, 0, true)
    end,

    --===========================--
    -- cardInstance:setFrontBg() --
    --===========================--
    setFrontBg = function(self, path)
        path = path or self.Card.FrontBgPath
        BlzFrameSetTexture(BlzFrameGetChild(self.Frame, 1), path, 0, true)
        BlzFrameSetTexture(BlzFrameGetChild(self.ZoomFrame, 1), path, 0, true)
    end,

    --===========================--
    -- cardInstance:setCardArt() --
    --===========================--
    setCardArt = function(self, path)
        path = path or self.Card.CardArtPath
        BlzFrameSetTexture(BlzFrameGetChild(self.Frame, 2), path], 0, true)
        BlzFrameSetTexture(BlzFrameGetChild(self.ZoomFrame, 2), path, 0, true)
    end,

    --=============================--
    -- cardInstance:setTitleText() --
    --=============================--
    setTitleText = function(self, text)
        text = text or self.Card.TitleText
        BlzFrameSetText(BlzFrameGetChild(self.Frame, 3), text)
        BlzFrameSetText(BlzFrameGetChild(self.ZoomFrame, 3), text)
    end,

    --============================--
    -- cardInstance:setDescText() --
    --============================--
    setDescText = function(self, text)
        text = text or self.Card.DescText
        BlzFrameSetText(BlzFrameGetChild(self.Frame, 4), text)
        BlzFrameSetText(BlzFrameGetChild(self.ZoomFrame, 4), text)
    end
    },{
    
    --===========--
    -- Metatable --
    --===========--

})



--=========--
return libCCG
--=========--
