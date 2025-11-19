local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCScavenge = require("05_npc_actions/PZNS_NPCScavenge")

local PZNS_GOAPScavenge = {}
PZNS_GOAPScavenge.name = "PZNS_GOAP_Scavenge"
PZNS_GOAPScavenge.preconditions = {isScavengeLocationAvailable = true}
PZNS_GOAPScavenge.effects = {hasScavengedItem = true}
PZNS_GOAPScavenge.cost = 1.0

function PZNS_GOAPScavenge:activate(npcSurvivor, scavengeLocation)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_NPCScavenge.execute(npcSurvivor, scavengeLocation)
end
return PZNS_GOAPScavenge;