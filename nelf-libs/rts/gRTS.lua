--=====--
gRTS = {}
--=====--



---------------------------------------------------------
-- Decimal Leftovers for Int Resources and Tech Levels --
-- k: playerstate or techId                            --
-- v: table {k: playerId+1   v: real}                  --
---------------------------------------------------------
gRTS.leftover = {}
gRTS.leftover[PLAYER_STATE_RESOURCE_GOLD]      = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
gRTS.leftover[PLAYER_STATE_RESOURCE_LUMBER]    = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
gRTS.leftover[PLAYER_STATE_RESOURCE_FOOD_USED] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
gRTS.leftover[PLAYER_STATE_RESOURCE_FOOD_CAP]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
