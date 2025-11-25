local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

-- distance thresholds (tweak to taste)
local TerminatorFollowRange = 30      -- tiles within which NPC will follow target
local WalkStopRange = 1.5               -- tiles considered "reached" when walking
local RunThresholdDistance = 20         -- tiles above which NPC should run instead of walk

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
		isRunToLocationAvailable = false,
		isWalkToLocationAvailable = false,
		hasReachedRunToLocation = false,
		hasReachedWalkToLocation = false,

        -- target position (filled at runtime)
        targetX = nil,
        targetY = nil,
        targetZ = nil,
        distanceFromTarget = nil,

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

function PZNS_GOAPWorldState.PZNS_CreateWorldState()
	local worldState = defaults()
	return worldState
end

function PZNS_GOAPWorldState.buildWorldState(npcSurvivor, targetID)
    local worldState = defaults()

    targetID = targetID or "Player0"
    print("PZNS_GOAPWorldState.buildWorldState: start targetID=", tostring(targetID), " npcSurvivor=", tostring(npcSurvivor))

     -- NPC
     if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
         print("PZNS_GOAPWorldState.buildWorldState: invalid npcSurvivor or missing iso player")
         return worldState
     end
     local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
     print("PZNS_GOAPWorldState.buildWorldState: npcIsoPlayer=", tostring(npcIsoPlayer))

    -- Target resolution: accept "PlayerN" strings or numeric index; fallback to Player0
    if targetID ~= "" and targetID ~= npcSurvivor.followTargetID then
        npcSurvivor.followTargetID = targetID
    end
    local targetIsoPlayer
    if type(targetID) == "string" then
        local idx = tonumber(targetID:match("Player(%d+)"))
        print("PZNS_GOAPWorldState: parsed target index=", tostring(idx))
        if idx then targetIsoPlayer = getSpecificPlayer(idx) end
    elseif type(targetID) == "number" then
        targetIsoPlayer = getSpecificPlayer(targetID)
    end
    if not targetIsoPlayer then
        print("PZNS_GOAPWorldState: falling back to getSpecificPlayer(0)")
        targetIsoPlayer = getSpecificPlayer(0)
    end
    if not targetIsoPlayer then
        print("PZNS_GOAPWorldState: no targetIsoPlayer resolved, returning defaults")
        return worldState
    end
    print("PZNS_GOAPWorldState: resolved targetIsoPlayer=", tostring(targetIsoPlayer))
    -- expose resolved IsoPlayer for callers
    worldState.targetIsoPlayer = targetIsoPlayer

    -- basic alive check
    if targetIsoPlayer:isAlive() == false then
        worldState.isTargetDead = true
    end

    -- target coordinates
    local tx, ty, tz = targetIsoPlayer:getX(), targetIsoPlayer:getY(), targetIsoPlayer:getZ()
    worldState.targetX = tx
    worldState.targetY = ty
    worldState.targetZ = tz

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

    -- target player's current square (if needed by actions)
    local playerSquare = targetIsoPlayer:getCurrentSquare()
    worldState.targetSquare = playerSquare

	-- Health
	if npcIsoPlayer:getBodyDamage():getOverallBodyHealth() <= 30 then
		worldState.isHealthLow = true
	end
	return worldState
end

return PZNS_GOAPWorldState
