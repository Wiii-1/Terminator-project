local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_NPCHuntPlayer = require("05_npc_actions/PZNS_NPCHuntPlayer")

local PZNS_GOAPHuntPlayer = {}
PZNS_GOAPHuntPlayer.name = "PZNS_GOAP_Hunt_Player"
PZNS_GOAPHuntPlayer.preconditions = {isPlayerVisible = true}
PZNS_GOAPHuntPlayer.effects = {hasReachedPlayer = true}
PZNS_GOAPHuntPlayer.cost = 1.0

function PZNS_GOAPHuntPlayer:activate(npcSurvivor, targetID)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_NPCHuntPlayer.execute(npcSurvivor, targetID)
end

return PZNS_GOAPHuntPlayer;