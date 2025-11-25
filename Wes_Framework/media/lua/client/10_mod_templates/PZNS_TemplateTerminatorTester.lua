local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")

local npcSurvivorID = "PZNS_Terminator"

---@param mpPlayerID any
function PZNS_SpawnTerminatorTester(mpPlayerID)
	local isNPCActive = PZNS_NPCsManager.getActiveNPCBySurvivorID(npcSurvivorID)
	local defaultID = 0
	--
	local playerID = "Player" .. tostring(defaultID)
	if isNPCActive == nil then
		local playerSurvivor = getSpecificPlayer(defaultID)
		local npcSurvivor = PZNS_NPCsManager.createNPCSurvivor(
			npcSurvivorID, -- Unique identifier
			false, -- isFemale
			"Terminator", -- Surname
			"The", -- Forename
			playerSurvivor:getSquare() -- Spawn at
		)
		if npcSurvivor ~= nil then
			-- Stats
			PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Strength", 5)
			PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Fitness", 5)
			PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Aiming", 5)
			PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Reloading", 5)
			PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Sneak", 5)
			PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Nimble", 5)
			PZNS_UtilsNPCs.PZNS_AddNPCSurvivorTraits(npcSurvivor, "Lucky")
			-- Clothes
			PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Trousers_Denim")
			PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Shoes_ArmyBoots")
			PZNS_UtilsNPCs.PZNS_AddItemToInventoryNPCSurvivor(npcSurvivor, "Base.BaseballBat")
			-- Weapons
			PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, "Base.Shotgun")
			PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(npcSurvivor, "Base.ShotgunShells", 12)
			-- Job
			PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, "Terminator")
			PZNS_UtilsNPCs.PZNS_SetNPCFollowTargetID(npcSurvivor, playerID)
			npcSurvivor.canAttack = true
			npcSurvivor.affection = 0
			PZNS_UtilsDataNPCs.PZNS_SaveNPCData(npcSurvivorID, npcSurvivor)
		end
	end
end

-- Delete Terminator
function PZNS_DeleteTerminatorTester(mpPlayerID)
	local npcSurvivor = PZNS_NPCsManager.getActiveNPCBySurvivorID(npcSurvivorID)
	PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor)
	PZNS_NPCsManager.deleteActiveNPCBySurvivorID(npcSurvivorID)
end
