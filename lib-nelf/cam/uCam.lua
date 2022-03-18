compiletime(function()
local u;
--=====================================================--
-- [x000] CamTargetGhost                               --
-- An invisible unit used to lock the camera.          --
-- Disables camera panning by locking it to this unit. --
--=====================================================--
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
currentMap.objects.unit['x000'] = u
end)
