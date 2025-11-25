local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WalkTo = require("05_npc_actions/PZNS_WalkTo")

local PZNS_GOAPWalkTo = {}
PZNS_GOAPWalkTo.name = "PZNS_GOAP_Walk_To"
PZNS_GOAPWalkTo.preconditions = {isWalkToLocationAvailable = true}
PZNS_GOAPWalkTo.effects = {hasReachedWalkToLocation = true}
PZNS_GOAPWalkTo.cost = 1.0

function PZNS_GOAPWalkTo:activate(npcSurvivor, walkToLocation)
    return PZNS_WalkTo.execute(npcSurvivor, walkToLocation)
end

return PZNS_GOAPWalkTo;
