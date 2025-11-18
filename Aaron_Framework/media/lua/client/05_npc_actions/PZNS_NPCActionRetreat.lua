--[[
    PZNS_NPCActionRetreat.lua - Reusable Retreat Action for NPCs
    
    Enables any NPC to move to safe zones during danger
    Can be used for defensive positioning or escaping threats
]]

local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_GeneralAI = require("07_npc_ai/PZNS_GeneralAI");

local PZNS_NPCActionRetreat = {};

---Execute Retreat Action - Move to safe zone (job square)
---@param npcSurvivor any
---@return boolean success
function PZNS_NPCActionRetreat.execute(npcSurvivor)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false;
    end
    
    -- Move to job square (safe zone)
    PZNS_GeneralAI.PZNS_WalkToJobSquare(npcSurvivor);
    
    return true;
end

---Retreat with custom destination
---@param npcSurvivor any
---@param safeSquare any Target safe square to retreat to
---@return boolean success
function PZNS_NPCActionRetreat.executeToSquare(npcSurvivor, safeSquare)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) or not safeSquare then
        return false;
    end
    
    -- Move to specified safe square
    PZNS_GeneralAI.PZNS_WalkToTargetSquare(npcSurvivor, safeSquare);
    
    return true;
end

---Retreat while under fire (run instead of walk)
---@param npcSurvivor any
---@return boolean success
function PZNS_NPCActionRetreat.executeEmergency(npcSurvivor)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false;
    end
    
    -- Run to job square
    PZNS_GeneralAI.PZNS_RunToJobSquare(npcSurvivor);
    
    return true;
end

---Get action metadata
---@return table metadata
function PZNS_NPCActionRetreat.getMetadata()
    return {
        name = "Retreat",
        cost = 3.0,
        duration = 1.0,
        description = "Move to safe zone to avoid threats"
    };
end

return PZNS_NPCActionRetreat;