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
		distanceFromTarget = 0,
		isWalkToLocationAvailable = false,
		targetX = 0,
		targetY = 0,
		targetZ = 0,

		-- Weapon related
		handItem = "",
		ammoCount = 0,
		isWeaponRanged = false,
		isWeaponEquipped = false,
		hasWeapon = false,
		hasAmmoInChamber = false,
		isWeaponAimed = false,

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

function PZNS_GOAPWorldState.buildWorldState(npcSurvivor)
	local worldState = defaults()
	local targetID = "Player" .. tostring(0)

	-- NPC
	if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
		return worldState
	end
	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject

<<<<<<< HEAD
    -- get current time (fallback if os.clock missing)
    local now = (os and os.clock and os.clock()) or ((socket and socket.gettime and socket.gettime()) or 0)
=======
	-- Target
	if targetID ~= "" and targetID ~= npcSurvivor.followTargetID then
		npcSurvivor.followTargetID = targetID
	end
	if not targetID or targetID == "" then
		print(string.format("Invalid targetID (%s) for Terminator", targetID))
		return worldState
	end

	local targetIsoPlayer = getSpecificPlayer(0)
>>>>>>> c7a116e (final struggle)

	if targetIsoPlayer == nil then
		return worldState
	end

	if targetIsoPlayer:isAlive() == false then
		worldState.isTargetDead = true
	end

	-- Distace between NPC and target
	local distanceFromTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetIsoPlayer)
	worldState.distanceFromtarget = distanceFromTarget
	if distanceFromTarget <= TerminatorFollowRange then
		worldState.isTargetInFollowRange = true
	end

<<<<<<< HEAD
    -- NPC validity
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return worldState
    end
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    print("PZNS_GOAPWorldState.buildWorldState: npcIsoPlayer=", tostring(npcIsoPlayer))

    -- resolve targetIsoPlayer from targetID (accept "PlayerN" or numeric index), fall back to Player0
    local targetIsoPlayer = nil
    if type(targetID) == "string" then
        local idx = tonumber(targetID:match("Player(%d+)"))
        if idx then targetIsoPlayer = getSpecificPlayer(idx) end
    elseif type(targetID) == "number" then
        targetIsoPlayer = getSpecificPlayer(targetID)
    end
    if not targetIsoPlayer then
        targetIsoPlayer = getSpecificPlayer(0)
    end
    if not targetIsoPlayer then
        return worldState
    end
    -- expose resolved IsoPlayer and coords
    worldState.targetIsoPlayer = targetIsoPlayer
    if targetIsoPlayer:isAlive() == false then worldState.isTargetDead = true end
    local tx, ty, tz = targetIsoPlayer:getX(), targetIsoPlayer:getY(), targetIsoPlayer:getZ()
    worldState.targetX = tx; worldState.targetY = ty; worldState.targetZ = tz

    -- Distance between NPC and target (use utility if available, else fallback)
    local distanceFromTarget = nil
    if PZNS_WorldUtils and PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects then
        distanceFromTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetIsoPlayer)
    else
        local dx = npcIsoPlayer:getX() - tx
        local dy = npcIsoPlayer:getY() - ty
        distanceFromTarget = math.sqrt(dx*dx + dy*dy)
    end
    worldState.distanceFromTarget = distanceFromTarget
    print("PZNS_GOAPWorldState: distanceFromTarget=", tostring(distanceFromTarget))

    -- visibility (safe)
    local ok, canSee = pcall(function() return npcIsoPlayer and targetIsoPlayer and npcIsoPlayer:CanSee(targetIsoPlayer) end)
    worldState.isTargetVisible = ok and (canSee == true)
    print("PZNS_GOAPWorldState: isTargetVisible=", tostring(worldState.isTargetVisible))

    -- follow/follow-range
    if distanceFromTarget <= TerminatorFollowRange then
        worldState.isTargetInFollowRange = true
    end

	
    -- decide run vs walk availability
    -- hasReachedWalkToLocation: close enough to stop walking
    if distanceFromTarget <= WalkStopRange then
        worldState.hasReachedWalkToLocation = true
        worldState.isWalkToLocationAvailable = false
        worldState.isRunToLocationAvailable = false
    else
        worldState.hasReachedWalkToLocation = false
        -- prefer running for long distances
        if distanceFromTarget >= RunThresholdDistance then
            worldState.isRunToLocationAvailable = true
            worldState.isWalkToLocationAvailable = false
        else
            worldState.isWalkToLocationAvailable = true
            worldState.isRunToLocationAvailable = false
        end
    end
=======
	worldState.isTargetVisible = npcIsoPlayer:CanSee(targetIsoPlayer)
>>>>>>> c7a116e (final struggle)

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
		worldState.isWeaponAimed = true
	end

	-- Health
	if npcIsoPlayer:getBodyDamage():getOverallBodyHealth() <= 30 then
		worldState.isHealthLow = true
	end

	-- Location Based
	-- isWalkToLocationAvailable
	local tx, ty, tz = targetIsoPlayer:getX(), targetIsoPlayer:getY(), targetIsoPlayer:getZ()

	worldState.targetX = tx
	worldState.targetY = ty
	worldState.targetZ = tz

	return worldState
end

return PZNS_GOAPWorldState
