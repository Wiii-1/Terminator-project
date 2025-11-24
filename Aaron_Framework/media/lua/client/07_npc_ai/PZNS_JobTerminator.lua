local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")
local PZNS_GOAPPlanner = require("07_npc_ai/PZNS_GOAPPlanner")
local GOAPHuntPlayer = require("05_npc_actions/GOAPActions/GOAPHuntPlayer")

-- Terminator target Player
local function getTargetIsoPlayerByID(targetID)
	local targetIsoPlayer
	--
	if targetID == "Player0" then
		targetIsoPlayer = getSpecificPlayer(0)
	else
		local targetNPC = PZNS_NPCsManager.getActiveNPCBySurvivorID(targetID)
		targetIsoPlayer = targetNPC.npcIsoPlayerObject
	end
	return targetIsoPlayer
end

-- Terminator within folow range of the player
local function isTerminatorInFollowRange(npcIsoPlayer, targetIsoPlayer)
	local distanceFromTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetIsoPlayer)
	if distanceFromTarget > CompanionFollowRange then
		return false
	end
	return true
end

--- @param npcSurvivor PZNS_NPCSurvivor
--- @param targetID string
function PZNS_JobTerminator(npcSurvivor, targetID)
	-- NPC validations
	if PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) == false then
		return
	end
	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
	if targetID ~= "" and targetID ~= npcSurvivor.followTargetID then
		npcSurvivor.followTargetID = targetID
	end

	if not targetID or targetID == "" then
		print(string.format("Invalid targetID (%s) for Terminator job", targetID))
		PZNS_NPCSpeak(npcSurvivor, string.format("Can't follow '%s' (invalid target)!", targetID))
		PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, "Wander In Cell")
		return
	end
	-- Player validations
	local targetIsoPlayer = getTargetIsoPlayerByID(targetID)
	if targetIsoPlayer == nil then
		return
	end
end

--- Quick test helper: invoke GOAPHuntPlayer.perform once and print results to the console/log.
--- @param npcSurvivor table (required) - the NPC survivor object
--- @param targetID string (optional) - e.g. "Player0"
function PZNS_TestGOAPHuntPlayer(npcSurvivor, targetID)
    if not npcSurvivor then
        print("PZNS_TestGOAPHuntPlayer: missing npcSurvivor")
        return
    end
    targetID = targetID or "Player0"

    print("PZNS_TestGOAPHuntPlayer: starting test for npc:", tostring(npcSurvivor.survivorID or npcSurvivor.id or "<unknown>"), " targetID=", tostring(targetID))

    local ok, res = pcall(function()
        return GOAPHuntPlayer:perform(npcSurvivor, targetID, 0.033)
    end)

    if not ok then
        print("PZNS_TestGOAPHuntPlayer: ERROR running GOAPHuntPlayer.perform ->", tostring(res))
    else
        print("PZNS_TestGOAPHuntPlayer: GOAPHuntPlayer.perform returned ->", tostring(res))
    end

    -- show markers/worldstate-relevant fields so you can see side-effects
    print("PZNS_TestGOAPHuntPlayer: npc markers:",
        "walkToX=", tostring(npcSurvivor.walkToX),
        "walkToY=", tostring(npcSurvivor.walkToY),
        "runToX=", tostring(npcSurvivor.runToX),
        "lastKnownX=", tostring(npcSurvivor.lastKnownPlayerX),
        "lastKnownPlayer=", tostring(npcSurvivor.lastKnownPlayer))
end
