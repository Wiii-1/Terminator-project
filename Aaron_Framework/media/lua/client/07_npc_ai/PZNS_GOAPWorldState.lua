local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

local PZNS_GOAPWorldState = {}

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> e038117 (Merge conflict and git test)
local function defaults()
	return {
<<<<<<< HEAD
		isTargetVisible = false, -- di ko ininclude yung isTargetInAttackRange, isUnderAttack at isAtPatrolPoint
=======
local function defaults()
	return {
		isTargetVisible = false,
>>>>>>> 8a4cfa7 (world state)
=======
local function defaults()
	return {
		isTargetVisible = false, -- di ko ininclude yung isTargetInAttackRange, isUnderAttack at isAtPatrolPoint
>>>>>>> 9f85c23 (world state and JobTerminator)
		isTargetInAttackRange = false,
=======
		isTargetVisible = false, -- di ko ininclude yung isTargetInAttackRange, isUnderAttack at isAtPatrolPoint,
>>>>>>> 53ddd19 (Change AI)
		isTargetInFollowRange = false,
		isTargetInAttackRange = false,
		isHealthLow = false,
		isAmmoLow = false,
		isWeaponEquipped = false,
		isTargetDead = false,
	}
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> e038117 (Merge conflict and git test)
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

	-- Primary
	local handItem = npcIsoPlayer:getPrimaryHandItem()
	if handItem == nil then
		return worldState
	end
	worldState.isWeaponEquipped = handItem:IsWeapon()

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

		if ammoCount <= 5 then
			worldState.isAmmoLow = true
		end
	else
		return worldState
	end

	-- Health
	if npcIsoPlayer:getBodyDamage():getOverallBodyHealth() <= 30 then
		worldState.isHealthLow = true
	end
	return worldState
end

return PZNS_GOAPWorldState
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> e8192a9 (test)
local function defaults ()
    return {
        isTargetVisible = false,
        isTargetInAttackRange = false,
        isTargetInFollowRange = false,
        isHealthLow = false,
        isAmmoLow = false,
        isWeaponEquipped = false,
        isUnderAttack = false,
        isAtPatrolPoint = false,
    }
<<<<<<< HEAD
=======
>>>>>>> 8a4cfa7 (world state)
=======
>>>>>>> e8192a9 (test)
=======
>>>>>>> 9f85c23 (world state and JobTerminator)
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

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
return PZNS_GOAPWorldState;
<<<<<<< HEAD
>>>>>>> e6b9386 (world state done)
=======
>>>>>>> e46b70d (Update PZNS_GOAPWorldState.lua)
=======
return PZNS_GOAPWorldState
>>>>>>> 8a4cfa7 (world state)
=======
return PZNS_GOAPWorldState;
>>>>>>> e8192a9 (test)
=======
return PZNS_GOAPWorldState
>>>>>>> 9f85c23 (world state and JobTerminator)
=======
>>>>>>> e038117 (Merge conflict and git test)
=======

>>>>>>> 2cb879a (fixed WorldState)
