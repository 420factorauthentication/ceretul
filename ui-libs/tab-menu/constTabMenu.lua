--===================--
local constTabMenu = {}
--===================--



----------------------------------
-- Menu Size (in 0.8:0:6 scale) --
----------------------------------
constTabMenu.menuSize = 0.5 --not including borders
constTabMenu.borderSize = 0.05 --size of one edge



-------------------------------------------------
-- Frame Children Sizes As Ratios Of Menu Size --
-------------------------------------------------
constTabMenu.closeButtonWidth  = (1/16)
constTabMenu.closeButtonHeight = (1/16)

constTabMenu.tabBarWidth       = 1 - constTabMenu.CloseButtonWidth
constTabMenu.tabBarHeight      = constTabMenu.CloseButtonHeight

constTabMenu.tabWidth          = (1/4) * constTabMenu.TabBarWidth
constTabMenu.tabHeight         = constTabMenu.TabBarHeight

constTabMenu.titleWidth        = (15/32)
constTabMenu.titleHeight       = (1/16)

constTabMenu.leftBodyWidth     = constTabMenu.TitleWidth
constTabMenu.leftBodyHeight    = (12/16)

constTabMenu.rightBodyWidth    = constTabMenu.TitleWidth
constTabMenu.rightBodyHeight   = (13/16)

constTabMenu.paddingHorizontal = (1 - constTabMenu.LeftBodyWidth - constTabMenu.RightBodyWidth) / 2
constTabMenu.paddingVertical   = (1 - constTabMenu.TabBarHeight - constTabMenu.RightBodyHeight) / 2



-----------------------------
-- Tab Bar Slider Settings --
-----------------------------
constTabMenu.sliderMin = 0
constTabMenu.sliderMax = 100
constTabMenu.sliderRange = math.abs(constTabMenu.sliderMax - constTabMenu.sliderMin)



--===============--
return constTabMenu
--===============--
