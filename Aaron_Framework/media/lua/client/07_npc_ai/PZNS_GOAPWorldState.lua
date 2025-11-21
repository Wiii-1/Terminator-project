local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

local PZNS_GOAPWorldState = {}

local function defaults()
	return {
		isTargetVisible = false, -- di ko ininclude yung isTargetInAttackRange, isUnderAttack at isAtPatrolPoint
		isTargetInAttackRange = false,
		isTargetInFollowRange = false,
		isHealthLow = false,
		isAmmoLow = false,
		isWeaponEquipped = false,
		isUnderAttack = false,
		isAtPatrolPoint = false,
	}
end

function PZNS_GOAPWorldState.PZNS_CreateWorldState()
	local worldState = defaults()
	return worldState
end

function PZNS_GOAPWorldState.buildWorldState(npcSurvivor, targetID)
	-- NPC
	if PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
		return worldState
	end
	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject

	-- Target
	if targetID ~= "" and targetID ~= npcSurvivor.followTargetID then
		npcSurvivor.followTargetID = targetID
	end
	if not targetID or targetID == "" then
		print(string.format("Invalid targetID (%s) for Terminator", targetID))
		return worldState
	end
	local targetIsoPlayer = getTargetIsoPlayerByID(targetID)
	--
	if targetIsoPlayer == nil then
		return worldState
	end

	-- Distace between NPC and target
	local distanceFromTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetIsoPlayer)
	if distanceFromTarget <= TerminatorFollowRange then
		worldState.isTargetInFollowRange = true
	end

	if distanceFromTarget <= 30 then
		worldState.isTargetVisible = true
	end

	-- Primary
	local handItem = npcIsoPlayer:getPrimaryHandItem()
	if handItem == nil then
		return worldState
	end

	worldState.isWeaponEquipped = handItem:isWeapon()
	-- Ammo
	local ammoCount
	if not handItem:isRanged() and not andItem:IsWeapon() then
		return worldState
	else
		local npc_inventory = npcIsoPlayer:getInventory()
		local ammoType = handItem:getAmmoType()
		local currentAmmo = handItem:getCurrentAmmoCount()
		local bullet = npc_inventory:getItemCount(ammoType)
		ammoCount = bullet + currentAmmo
	end

	if ammoCount <= 5 then
		worldState.isAmmoLow = true
	end

	-- Health
	if npcIsoPlayer:getBodyDamage():getOverallBodyHealth() <= 30 then
		worldState.isHealthLow = true
	end

	return worldState
end

return PZNS_GOAPWorldState
