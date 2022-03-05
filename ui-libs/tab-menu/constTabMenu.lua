--===================--
local constTabMenu = {}
--===================--



----------------------------------
-- Menu Size (in 0.8:0:6 scale) --
----------------------------------
constTabMenu.menuSize   = 0.5   --not including borders
constTabMenu.borderSize = 0.025 --size of one edge



-------------------------------------------------
-- Frame Children Sizes As Ratios Of Menu Size --
-------------------------------------------------
constTabMenu.closeButtonWidth  = (1/16)
constTabMenu.closeButtonHeight = (1/16)

constTabMenu.tabBarWidth       = 1 - constTabMenu.closeButtonWidth
constTabMenu.tabBarHeight      = constTabMenu.closeButtonHeight

constTabMenu.tabWidth          = (1/4) * constTabMenu.tabBarWidth
constTabMenu.tabHeight         = constTabMenu.tabBarHeight

constTabMenu.titleWidth        = (15/32)
constTabMenu.titleHeight       = (1/16)

constTabMenu.leftBodyWidth     = constTabMenu.titleWidth
constTabMenu.leftBodyHeight    = (12/16)

constTabMenu.rightBodyWidth    = constTabMenu.titleWidth
constTabMenu.rightBodyHeight   = (13/16)

constTabMenu.paddingHorizontal = (1 - constTabMenu.leftBodyWidth - constTabMenu.rightBodyWidth) / 2
constTabMenu.paddingVertical   = (1 - constTabMenu.tabBarHeight - constTabMenu.rightBodyHeight) / 2

constTabMenu.tabSelectIndent   = constTabMenu.paddingVertical / 8



-----------------------------
-- Tab Bar Slider Settings --
-----------------------------
constTabMenu.sliderMin   = 0
constTabMenu.sliderMax   = 100
constTabMenu.sliderRange = math.abs(constTabMenu.sliderMax - constTabMenu.sliderMin)



-------------------
-- Texture Paths --
-------------------
-- constTabMenu.buttonUpTex   = "UI\\Widgets\\EscMenu\\Human\\human-options-menu-background.blp"
-- constTabMenu.buttonDownTex = "UI\\Widgets\\EscMenu\\Human\\human-options-menu-background.blp"
constTabMenu.buttonUpTex   = "EscMenuButtonBackdropTemplate"
constTabMenu.buttonDownTex = "EscMenuButtonPushedBackground"



--===============--
return constTabMenu
--===============--
