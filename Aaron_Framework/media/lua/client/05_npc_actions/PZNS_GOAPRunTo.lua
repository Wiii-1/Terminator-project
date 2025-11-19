local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
<<<<<<< HEAD
local PZNS_RunTo = require("05_npc_actions/PZNS_RunTo")
=======
local PZNS_RunTo = require("05_npc_actions/PZNS_NPCRunTo")
>>>>>>> 3fb9774 (check)

local PZNS_GOAPRunTo = {}
PZNS_GOAPRunTo.name = "PZNS_GOAP_Run_To"
PZNS_GOAPRunTo.preconditions = {isRunToLocationAvailable = true}
PZNS_GOAPRunTo.effects = {hasReachedRunToLocation = true}
<<<<<<< HEAD
PZNS_GOAPRunTo.cost = 2.0

function PZNS_GOAPRunTo:activate(npcSurvivor, runToLocation)
    PZNS_RunTo.execute(npcSurvivor, runToLocation)
=======
PZNS_GOAPRunTo.cost = 1.0

function PZNS_GOAPRunTo:activate(npcSurvivor, runToLocation)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_RunTo.execute(npcSurvivor, runToLocation)
>>>>>>> 3fb9774 (check)
end

return PZNS_GOAPRunTo;