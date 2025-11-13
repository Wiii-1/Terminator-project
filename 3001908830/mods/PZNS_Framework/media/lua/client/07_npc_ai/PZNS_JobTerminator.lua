local PZNS_ManageJobs = require("07_npc_ai/PZNS_ManageJobs")
local GOAPTerminatorBrain = require("07_npc_ai/PZNS_GOAPTerminatorBrain")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

-- Terminator job: sets up NPC as a Terminator and triggers the GOAP brain once.
function PZNS_JobTerminator(npcSurvivor)
    if not npcSurvivor then return end

    -- Mark the npc as a Terminator
    npcSurvivor.jobName = "Terminator"
    npcSurvivor.isTerminator = true

    -- Ensure modData marker so server spawner or other systems know this is PZNS-managed
    if npcSurvivor.npcIsoPlayerObject and npcSurvivor.npcIsoPlayerObject.getModData then
        local ok, md = pcall(function() return npcSurvivor.npcIsoPlayerObject:getModData() end)
        if ok and md then
            md.isPZNS = true
            md.isTerminator = true
        end
    end

    -- Ensure NPC has appropriate invulnerability/support if helpers are available
    if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_SetNPCInvulnerable then
        pcall(function() PZNS_UtilsNPCs.PZNS_SetNPCInvulnerable(npcSurvivor, true) end)
    end

    -- Trigger the GOAP brain safely (will also be ticked from GeneralAI)
    pcall(function()
        GOAPTerminatorBrain.tick(npcSurvivor)
    end)
end

-- Register job in PZNS job manager (adds menu label and job mapping)
pcJobMgr = require("07_npc_ai/PZNS_ManageJobs")
if npcJobMgr and npcJobMgr.updatePZNSJobsTable then
    pcall(function()
        npcJobMgr.updatePZNSJobsTable("Terminator", PZNS_JobTerminator, "ContextMenu_PZNS_Terminator")
    end)
end

return PZNS_JobTerminator
