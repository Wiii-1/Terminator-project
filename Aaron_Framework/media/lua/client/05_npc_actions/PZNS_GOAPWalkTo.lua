local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
<<<<<<< HEAD
<<<<<<< HEAD
local PZNS_WalkTo = require("05_npc_actions/PZNS_WalkTo")
=======
local PZNS_WalkTo = require("05_npc_actions/PZNS_NPCWalkTo")
>>>>>>> 3fb9774 (check)
=======
local PZNS_WalkTo = require("05_npc_actions/PZNS_WalkTo")
>>>>>>> 0050aad (still fixing)

local PZNS_GOAPWalkTo = {}
PZNS_GOAPWalkTo.name = "PZNS_GOAP_Walk_To"
PZNS_GOAPWalkTo.preconditions = {isWalkToLocationAvailable = true}
PZNS_GOAPWalkTo.effects = {hasReachedWalkToLocation = true}
PZNS_GOAPWalkTo.cost = 1.0

function PZNS_GOAPWalkTo:activate(npcSurvivor, walkToLocation)
<<<<<<< HEAD
=======
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

>>>>>>> 3fb9774 (check)
    return PZNS_WalkTo.execute(npcSurvivor, walkToLocation)
end

return PZNS_GOAPWalkTo;
