local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_RunTo = require("05_npc_actions/PZNS_NPCRunTo")
local PZNS_WalkTo = require("05_npc_actions/PZNS_NPCWalkTo")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCsManager = require("07_npc_ai/PZNS_NPCsManager")

local HuntPlayer = {};

function PZNS_HuntPlayer.setLastKnown(npcSurvivor, x, y, z, sourcePlayer)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return
    end

    -- Set the last known position of the player for the NPC
    npcSurvivor.lastKnownPlayerX = x
    npcSurvivor.lastKnownPlayerY = y
    npcSurvivor.lastKnownPlayerZ = z
    npcSurvivor.lastKnownPlayer = sourcePlayer
end

function PZNS_HuntPlayer.execute(npcSurvivor)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return
    end

    local targetPlayer = npcSurvivor.lastKnownPlayer
    if not targetPlayer then
        return
    end

    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    local distanceToPlayer = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetPlayer)

    -- Decide whether to run or walk based on distance
    if distanceToPlayer > 5 then
        PZNS_RunTo.execute(npcSurvivor, targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ())
    else
        PZNS_WalkTo.execute(npcSurvivor, targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ())
    end

    -- If close enough, clear last known position
    if distanceToPlayer < 2 then
        npcSurvivor.lastKnownPlayerX = nil
        npcSurvivor.lastKnownPlayerY = nil
        npcSurvivor.lastKnownPlayerZ = nil
        npcSurvivor.lastKnownPlayer = nil
    end
end

return HuntPlayer