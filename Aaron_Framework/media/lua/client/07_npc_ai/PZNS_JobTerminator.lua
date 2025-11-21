local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")
local PZNS_GOAPPlanner = require("07_npc_ai/PZNS_GOAPPlanner")

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

	-- GOAP Planner
	-- Where goap planner will run
end
