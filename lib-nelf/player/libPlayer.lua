--================--
local libPlayer = {}
--================--



--=============================================================--
-- getPlayingPlayerIds()                                       --
--                                                             --
-- Returns an array of playerIds of currently playing players. --
--=============================================================--
libPlayer.getPlayingPlayerIds = function()
    local players = {}
    for i=0,23 do
        if GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING then
            table.insert(players, i)
        end
    end
    return players
end



--============--
return libPlayer
--============--
