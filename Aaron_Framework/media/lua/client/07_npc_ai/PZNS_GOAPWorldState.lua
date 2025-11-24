local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

local PZNS_GOAPWorldState = {}

local function defaults()
	return {
		-- Player / NPC related
		isTargetVisible = false,
		isTargetInFollowRange = false,
		isTargetInAttackRange = false,
		isHealthLow = false,
		isTargetDead = false,

		-- Location stuff
		isScavengeLocationAvailable = false,
		isRunToLocationAvailable = false,
		isWalkToLocationAvailable = false,
		hasReachedRunToLocation = false,
		hasReachedWalkToLocation = false,

		-- Weapon related
		handItem = "",
		ammoCount = 0,
		isWeaponRanged = false,
		isWeaponEquipped = false,
		hasWeapon = false,
		hasAmmoInChamber = false,
		hasWeaponAimed = false,

		-- Not sure
		hasWeaponPickedUp = false,
		hasScavengedItems = false,

		-- Add to PZNS_GOAP_WorldState
		-- isWeaponRanged
		-- handItem
		-- ammoCount - change isAmmoLow to ammoCount
		--
	}
end

function PZNS_GOAPWorldState.PZNS_CreateWorldState()
	local worldState = defaults()
	return worldState
end

function PZNS_GOAPWorldState.buildWorldState(npcSurvivor, options)
	options = options or {}
	local worldState = defaults()
	local heavyScan = options.heavyScan or false
	local targetID = "Player" .. tostring(0)

	-- NPC
	if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
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

	local targetIsoPlayer = getSpecificPlayer(0)

	if targetIsoPlayer == nil then
		return worldState
	end

	if targetIsoPlayer:isAlive() == false then
		worldState.isTargetDead = true
	end

	-- Distace between NPC and target
	local distanceFromTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetIsoPlayer)
	if distanceFromTarget <= TerminatorFollowRange then
		worldState.isTargetInFollowRange = true
	end

	if distanceFromTarget <= 30 then
		worldState.isTargetVisible = true
	end

	-- Inventory
	local inv = npcIsoPlayer:getInventory()
	local items = inv:getItems()

	for i = 1, items:size() - 1 do
		local item = items:get(i)
		if item:IsWeapon() then
			worldState.hasWeapon = true
		end
	end
	-- Primary
	local handItem = npcIsoPlayer:getPrimaryHandItem()
	if handItem == nil then
		return worldState
	end
	worldState.handItem = handItem
	worldState.isWeaponEquipped = handItem:IsWeapon()
	worldState.isWeaponRanged = handItem:isRanged()

	-- Ammo and Attack range
	local ammoCount
	if handItem:isRanged() and handItem:IsWeapon() then
		if distanceFromTarget < handItem:getMaxRange() then
			worldState.isTargetInAttackRange = true
		end

		local npc_inventory = npcIsoPlayer:getInventory()
		local ammoType = handItem:getAmmoType()
		local currentAmmo = handItem:getCurrentAmmoCount()
		local bullet = npc_inventory:getItemCount(ammoType)
		ammoCount = bullet + currentAmmo

		worldState.ammoCount = ammoCount

		if currentAmmo < 0 then
			worldState.hasAmmoInChamber = true
		end
	else
		return worldState
	end

	if npcIsoPlayer:NPCGetAiming() == true then
		worldState.hasWeaponAimed = true
	end

	-- Health
	if npcIsoPlayer:getBodyDamage():getOverallBodyHealth() <= 30 then
		worldState.isHealthLow = true
	end
	return worldState
end

return PZNS_GOAPWorldState
