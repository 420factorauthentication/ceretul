--=============--
local libVFX = {}
--=============--



--=========================================================--
-- class vfxTemplate                                       --
--                                                         --
-- Used to instantiate a War3 Effect with common settings. --
--                                                         --
-- RGB (255,255,255): Default colors of effect.            --
-- RGB (0,0,0): Either transparent or white.               --
--=========================================================--
libVFX.vfxTemplate = setmetatable({
    Name = "New VFX Template",

    ModelPath,  -- string

    ColorR = 255,  -- int (0-255)
    ColorG = 255,  -- int (0-255)
    ColorB = 255,  -- int (0-255)
    ColorA = 255,  -- int (0-255)

    ScaleX = 1.0,  -- real. Model size scalar
    ScaleY = 1.0,  -- real. Model size scalar
    ScaleZ = 1.0,  -- real. Model size scalar

    OffsetX = 0,  -- real. Offsets params passed to create()
    OffsetY = 0,  -- real. Offsets params passed to create()
    OffzetZ = 0,  -- real. Offsets params passed to create()

    RotateYaw   = 0,  -- real
    RotatePitch = 0,  -- real
    RotateRoll  = 0,  -- real

    AnimStart = 0.0,  -- real. Start effect anim midway
    AnimSpeed = 1.0,  -- real. Anim playback speed scalar

    --== Read-Only ==--
    Effect,  -- Handle to effect object

    --=============--
    -- Constructor --
    --=============--
    new = function(self, o)
        o = o or {}
        setmetatable(o, {__index = self})
        return o
    end,

    --========================================--
    -- effectTemplate:create()                --
    --   x: real                              --
    --   y: real                              --
    --   z: real = 0                          --
    --                                        --
    -- Creates an effect with these settings. --
    -- Returns a handle to that effect.       --
    --========================================--
    create = function(self, x, y, z)
        z = z or 0
        local effect = AddSpecialEffect(self.ModelPath, x + self.OffsetX, y + self.OffsetY)
        BlzSetSpecialEffectHeight(effect, z + self.OffsetZ)
        BlzSetSpecialEffectColor(effect, self.ColorR, self.ColorG, self.ColorB)
        BlzSetSpecialEffectAlpha(effect, self.ColorA)
        BlzSetSpecialEffectMatrixScale(effect, self.ScaleX, self.ScaleY, self.ScaleZ)
        BlzSetSpecialEffectYaw(effect, self.RotateYaw)
        BlzSetSpecialEffectPitch(effect, self.RotatePitch)
        BlzSetSpecialEffectRoll(effect, self.RotateRoll)
        BlzSetSpecialEffectTime(effect, self.AnimStart)
        BlzSetSpecialEffectTimeScale(effect, self.AnimSpeed)
        return effect
    end,
    },{

    --===========--
    -- Metatable --
    --===========--

})



--=========--
return libVFX
--=========--
