--[[
    PZNS_NPCActionHunt.lua - Reusable Hunt Action for NPCs
    
    Enables any NPC to actively search for threats in the environment
    Updates threat lists and explores buildings using WorldUtils
]]

local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils");
local PZNS_GeneralAI = require("07_npc_ai/PZNS_GeneralAI");

local PZNS_NPCActionHunt = {};

---Execute Hunt Action - Search for threats in environment
---@param npcSurvivor any
---@return boolean success
function PZNS_NPCActionHunt.execute(npcSurvivor)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false;
    end
    
    -- Update threat lists to get most recent world state
    PZNS_WorldUtils.PZNS_UpdateCellNPCsList();
    PZNS_WorldUtils.PZNS_UpdateCellZombiesList();
    
    -- Scan for any nearby threats
    local threatFound = PZNS_GeneralAI.PZNS_CheckForThreats(npcSurvivor);
    
    if threatFound then
        return true;  -- Threat detected, action successful
    end
    
    -- No threats detected, explore current building
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject;
    if npcIsoPlayer then
        PZNS_GeneralAI.PZNS_ExploreTargetBuilding(npcSurvivor, npcIsoPlayer:getSquare());
    end
    
    return true;
end

---Get action metadata
---@return table metadata
function PZNS_NPCActionHunt.getMetadata()
    return {
        name = "Hunt",
        cost = 1.0,
        duration = 0.5,
        description = "Search for threats in environment"
    };
end

return PZNS_NPCActionHunt;