--[[
    PZNS_NPCActionPatrol.lua - Reusable Patrol Action for NPCs
    
    Enables any NPC to patrol assigned zones and search for threats
    Uses GeneralAI to navigate to job square
]]

local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_GeneralAI = require("07_npc_ai/PZNS_GeneralAI");

local PZNS_NPCActionPatrol = {};

---Execute Patrol Action - Move through zone searching for threats
---@param npcSurvivor any
---@return boolean success
function PZNS_NPCActionPatrol.execute(npcSurvivor)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false;
    end
    
    -- Walk to assigned job square (patrol zone)
    PZNS_GeneralAI.PZNS_WalkToJobSquare(npcSurvivor);
    
    return true;
end

---Get action metadata
---@return table metadata
function PZNS_NPCActionPatrol.getMetadata()
    return {
        name = "Patrol",
        cost = 1.5,
        duration = 0.8,
        description = "Move through patrol zone searching for threats"
    };
end

return PZNS_NPCActionPatrol;