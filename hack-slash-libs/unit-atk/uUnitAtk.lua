compiletime(function()
local u;
--=============================================--
-- [x001] vfxDummy                             --
-- A unit with no collision.                   --
-- Create this and set it's model to make VFX. --
--=============================================--
u = currentMap.objects.unit['hpea']:clone()
--[[ type              ]] u.utyp = "Peon"
--[[ model             ]] u.umdl = ""
--[[ shadow type       ]] u.ushu = ""
--[[ collision size    ]] u.ucol = 0.0
--[[ movespeed         ]] u.umvs = 0
--[[ movement type     ]] u.umvt = "fly"
--[[ attack 1 range    ]] u.ua1r = 1
--[[ acquisition range ]] u.uacq = 1
--[[ abilities         ]] u.uabi = "Avul"
currentMap.objects.unit['x001'] = u
end)
