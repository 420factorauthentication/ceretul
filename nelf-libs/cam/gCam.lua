--=====--
gCam = {}
--=====--

-- < Modules > --
local libCam = require "libCam"
local libPlayer = require "libPlayer"



------------------
-- Terrain Fogs --
------------------
gCam.currTerrainFogs = {}
for k, v in pairs(libPlayer.getPlayingPlayerIds()) do
    gCam.currTerrainFogs[v+1] = libCam.terrainFog:new({
        FogStartZ  = 3000,
        FogEndZ    = 5000,
        FogStyle   = 0,
        FogDensity = 0.5,
        FogColorR  = 0,
        FogColorG  = 0,
        FogColorB  = 0
    })
end



----------------------------------
-- Ghost units used to lock cam --
----------------------------------
gCam.currCamGhostUnit  = {}
gCam.camGhostUnitReset = CreateUnit(Player(27), FourCC('x000'), 0, 0, 0)
