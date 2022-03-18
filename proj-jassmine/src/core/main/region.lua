--== TEST: UnitId() vs FourCC() ==--
-- local printUnitId = CreateTrigger()
-- BlzTriggerRegisterPlayerKeyEvent(printUnitId, Player(0), OSKEY_SPACE, 0, false)
-- TriggerAddAction(printUnitId, function()
--     print("UnitId('hpea'): " .. UnitId("hpea"))  --prints 0
--     print("FourCC('hpea'): " .. FourCC("hpea"))  --prints 1752196449
-- end)


--== TEST: REGION ENTER TRIGS ==--
-- local region0 = CreateRegion()
-- local region1 = CreateRegion()
-- local rectLeft = Rect(-400, -100, -200, 100)
-- local rectRight = Rect(200, -100,  400, 100)
-- RegionAddRect(region0, rectLeft)
-- RegionAddRect(region1, rectRight)
-- CreateUnit(Player(2), FourCC("hpea"), -400, -100, 0)
-- CreateUnit(Player(2), FourCC("hpea"), -400,  100, 0)
-- CreateUnit(Player(2), FourCC("hpea"), -200, -100, 0)
-- CreateUnit(Player(2), FourCC("hpea"), -200,  100, 0)
-- CreateUnit(Player(2), FourCC("hpea"),  200, -100, 0)
-- CreateUnit(Player(2), FourCC("hpea"),  200,  100, 0)
-- CreateUnit(Player(2), FourCC("hpea"),  400, -100, 0)
-- CreateUnit(Player(2), FourCC("hpea"),  400,  100, 0)
-- local regionEnterTrig = CreateTrigger()


--== TEST: MULTIPLE REGIONS FOR ONE TRIG: WORKS ==--
-- TriggerRegisterEnterRegionSimple(regionEnterTrig, region0)
-- TriggerRegisterEnterRegionSimple(regionEnterTrig, region1)
-- TriggerAddAction(regionEnterTrig, function()
--     print("unit entered region")
-- end)


--== TEST: REGISTER ENTER REGION EVENT WITH UNIT ALREADY INSIDE ==--
--== DOESNT TRIGGER ACTION FOR UNITS ALREADY INSIDE ==--
-- local registerEnterRegionEvent = CreateTrigger()
-- BlzTriggerRegisterPlayerKeyEvent(registerEnterRegionEvent, Player(0), OSKEY_SPACE, 0, false)
-- TriggerAddAction(registerEnterRegionEvent, function()
--     TriggerRegisterEnterRegionSimple(regionEnterTrig, region0)
--     TriggerRegisterEnterRegionSimple(regionEnterTrig, region1)
--     TriggerAddAction(regionEnterTrig, function()
--         print("unit entered region")
--     end)
--     print("registered enter region events")
-- end)


--== TEST: DIFF WAYS TO FILTER ENTERING UNITS ==--
--==================== WORKS ===================--
-- local conditionFilter = Condition(function()
--     local unit = GetFilterUnit()
--     print(GetUnitTypeId(unit))  --prints 1752196449
--     return true end)
-- TriggerRegisterEnterRegion(regionEnterTrig, region0, conditionFilter)

--==================== WORKS ===================--
-- local filterFilter = Filter(function()
--     local unit = GetFilterUnit()
--     print(GetUnitTypeId(unit))  --prints 1752196449
--     return true end)
-- TriggerRegisterEnterRegion(regionEnterTrig, region0, filterFilter)

--==================== WORKS ===================--
-- TriggerAddCondition(regionEnterTrig, Condition(function()
    -- local unit = GetEnteringUnit()
    -- print(GetUnitTypeId(unit))  --prints 1752196449
    -- return true end))
-- TriggerRegisterEnterRegionSimple(regionEnterTrig, region0)

--==================== WORKS ===================--
-- TriggerAddAction(regionEnterTrig, function()
    -- local unit = GetEnteringUnit()
    -- print(GetUnitTypeId(unit))  --prints 1752196449
-- end)
