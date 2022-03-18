--===============--
local constCCG = {}
--===============--



-----------
-- Enums --
-----------
constCCG.cardState = {
    null       = 0,
    handSlot1  = 1,
    handSlot2  = 2,
    handSlot3  = 3,
    handSlot4  = 4,
    handSlot5  = 5,
    handSlot6  = 6,
    handSlot7  = 7,
    handSlot8  = 8,
    handSlot9  = 9,
    handSlot10 = 10,
    deck       = 11,
    graveyard  = 12
}

constCCG.cardClass = {
    neutral  = 0,
    economic = 1,
    military = 2,
    spell    = 3
}



--===========--
return constCCG
--===========--
