local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

local PZNS_GOAPWorldState = {}

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
local function defaults()
	return {
		isTargetVisible = false, -- di ko ininclude yung isTargetInAttackRange, isUnderAttack at isAtPatrolPoint
=======
local function defaults()
	return {
		isTargetVisible = false,
>>>>>>> 8a4cfa7 (world state)
		isTargetInAttackRange = false,
		isTargetInFollowRange = false,
		isHealthLow = false,
		isAmmoLow = false,
		isWeaponEquipped = false,
		isUnderAttack = false,
		isAtPatrolPoint = false,
	}
<<<<<<< HEAD
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
end

function PZNS_GOAPWorldState.PZNS_CreateWorldState()
    local worldState = defaults()
    return worldState
end

function PZNS_GOAPWorldState.buildWorldState (npcSurvivor, optionals)
    optionals = optionals or {}
    local worldState = defaults()

    if PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then 
        return worldState
    end

    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject

    local handItem = npcIsoPlayer:getPrimaryHandItem()
    worldState.isWeaponEquipped = PZNS_WorldUtils.PZNS_IsItemWeapon(handItem)


    -- player visibility lng idk if tama to
    local target = npcSurvivor.currentTarget
    if target and PZNS_WorldUtils and PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(target) then 
        local targetIsoPlayer = target.npcIsoPlayerObject
        worldState.isTargetVisible = PZNS_WorldUtils.PZNS_IsObjectVisible(npcIsoPlayer, targetIsoPlayer)

        local distanceToTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetIsoPlayer)
        worldState.isTargetInAttackRange = distanceToTarget <= npcSurvivor.attackRange
        worldState.isTargetInFollowRange = distanceToTarget <= npcSurvivor.followRange
    end

    -- check ng range lng to sa player
    if target and target.getX then
        if PZNS_WorldUtils and PZNS_UtilsNPCs.PZNS_GetDistanceBetweenTwoObjects then
            local distanceToTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, target)
            worldState.isTargetInFollowRange = distanceToTarget <= npcSurvivor.followRange
        else 
            local dx = npcIsoPlayer:getX() - target:getX()
            local dy = npcIsoPlayer:getY() - target:getY()
            local distanceToTarget = math.sqrt(dx * dx + dy * dy)
            worldState.isTargetInFollowRange = distanceToTarget <= npcSurvivor.followRange
        end
    else
        return worldState
    end

    -- if i'm correct ron eto yung check ng ammo para sa isang ranged weapon
    if npcHandItem and npcHandItem.isRanged and npcHandItem:isRanged() then
        if npcHandItem:getAmmoType() then
            local ammoCount = npcIsoPlayer:getInventory():getItemCount(npcHandItem:getAmmoType())
            local currentAmmo = npcHandItem:getCurrentAmmoCount() or 0
            local perfire = npcHandItem:getPerFire() or 1
            ammoCount = ammoCount + currentAmmo
            worldState.isAmmoLow = ammoCount < 5
        else
            worldState.isAmmoLow = false
        end
    else
        worldState.isAmmoLow = false
    end

    -- health tracker lng to
    if npcIsoPlayer:getHealth() then 
        worldState.isHealthLow = (npcSurvivor.healthThreshold and npcIsoPlayer:getHealth() < npcSurvivor.healthThreshold) or (npcIsoPlayer:getHealth() < 30)
    else
        worldState.isHealthLow = false
    end

    return worldState
end

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
