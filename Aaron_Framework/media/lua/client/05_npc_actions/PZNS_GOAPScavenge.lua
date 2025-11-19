local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCScavenge = require("05_npc_actions/PZNS_NPCScavenge")

local PZNS_GOAPScavenge = {}
PZNS_GOAPScavenge.name = "PZNS_GOAP_Scavenge"
PZNS_GOAPScavenge.preconditions = {isScavengeLocationAvailable = true}
PZNS_GOAPScavenge.effects = {hasScavengedItem = true}
<<<<<<< HEAD
PZNS_GOAPScavenge.cost = 8.0

function PZNS_GOAPScavenge:activate(npcSurvivor, scavengeLocation)
    PZNS_NPCScavenge.execute(npcSurvivor, scavengeLocation)
=======
PZNS_GOAPScavenge.cost = 1.0

function PZNS_GOAPScavenge:activate(npcSurvivor, scavengeLocation)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_NPCScavenge.execute(npcSurvivor, scavengeLocation)
>>>>>>> 6dcdeba (wrapped actions for GOAP Planner compatibility)
end
return PZNS_GOAPScavenge;