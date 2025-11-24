local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_RunTo = require("05_npc_actions/PZNS_RunTo")
local PZNS_WalkTo = require("05_npc_actions/PZNS_WalkTo")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")

local PZNS_HuntPlayer = {}

function PZNS_HuntPlayer.setLastKnown(npcSurvivor, x, y, z, sourcePlayer)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then return end
    npcSurvivor.lastKnownPlayerX = x
    npcSurvivor.lastKnownPlayerY = y
    npcSurvivor.lastKnownPlayerZ = z
    npcSurvivor.lastKnownPlayer = sourcePlayer
end

function PZNS_HuntPlayer.execute(npcSurvivor)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then return true end

    local targetPlayer = npcSurvivor.lastKnownPlayer
    if not targetPlayer then return true end

    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    local distanceToPlayer = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetPlayer) or math.huge

    if distanceToPlayer > 5 then
        PZNS_RunTo.execute(npcSurvivor, targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ())
    else
        PZNS_WalkTo.execute(npcSurvivor, targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ())
    end

    if distanceToPlayer < 2 then
        npcSurvivor.lastKnownPlayerX = nil
        npcSurvivor.lastKnownPlayerY = nil
        npcSurvivor.lastKnownPlayerZ = nil
        npcSurvivor.lastKnownPlayer = nil
        return true
    end

    return false
end

return PZNS_HuntPlayer