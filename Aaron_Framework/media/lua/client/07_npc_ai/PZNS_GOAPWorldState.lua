local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

local PZNS_GOAPWorldState = {}

local function defaults()
	return {
		isTargetVisible = false, -- di ko ininclude yung isTargetInAttackRange, isUnderAttack at isAtPatrolPoint,
		isTargetInFollowRange = false,
		isTargetInAttackRange = false,
		isHealthLow = false,
		isAmmoLow = false,
		isWeaponEquipped = false,
		isTargetDead = false,
		isRunToLocationAvailable =false,
		isWeaponAvailable = false,
		isScavengeLocationAvailable = false,
		isWalkToLocationAvailable = false,
		hasAmmoAvailable = false,
		hasWeaponReloaded = false,
		hasWeaponAimed = false,	
		hasReachedRunToLocation = false,
		hasWeaponEquipped = false,
		hasWeaponPickedUp = false,
		hasScavengedItems = false,
		hasReachedWalkToLocation = false,
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

	-- Primary
	local handItem = npcIsoPlayer and npcIsoPlayer.getPrimaryHandItem and npcIsoPlayer:getPrimaryHandItem() or nil
    worldState.isWeaponEquipped = false
    worldState.isWeaponAvailable = false
    worldState.hasWeaponEquipped = false
    worldState.hasWeaponPickedUp = false
    worldState.hasWeaponAimed = worldState.hasWeaponAimed or false
    worldState.hasWeaponReloaded = worldState.hasWeaponReloaded or false

    if handItem and handItem:IsWeapon() then
        worldState.isWeaponEquipped = true
        worldState.isWeaponAvailable = true
        worldState.hasWeaponEquipped = true

        -- Ammo and attack range (only for ranged weapons)
        if handItem.isRanged and handItem:IsWeapon() and handItem:isRanged() and handItem:IsWeapon() then
            local npc_inventory = npcIsoPlayer:getInventory()
            local ammoType = handItem:getAmmoType()
            local currentAmmo = handItem:getCurrentAmmoCount() or 0
            local bullet = (ammoType and npc_inventory and npc_inventory:getItemCount(ammoType)) or 0
            local ammoCount = (bullet or 0) + (currentAmmo or 0)

            worldState.hasAmmoAvailable = ammoCount > 0
            worldState.isAmmoLow = (ammoCount <= 5)

            local maxRange = handItem.getMaxRange and handItem:getMaxRange() or 0
            if distanceFromTarget < maxRange then
                worldState.isTargetInAttackRange = true
            else
                worldState.isTargetInAttackRange = false
            end
        else
            -- melee weapon or no ranged API available
            worldState.isTargetInAttackRange = false
            worldState.hasAmmoAvailable = false
            worldState.isAmmoLow = false
        end
    else
        -- no handItem or not a weapon
        worldState.isWeaponEquipped = false
        worldState.isWeaponAvailable = false
        worldState.hasWeaponEquipped = false
        worldState.hasAmmoAvailable = false
        worldState.isAmmoLow = false
        worldState.isTargetInAttackRange = false
    end

	-- Health
	if npcIsoPlayer:getBodyDamage():getOverallBodyHealth() <= 30 then
		worldState.isHealthLow = true
	end
	return worldState
end

return PZNS_GOAPWorldState

