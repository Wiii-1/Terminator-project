local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

local PZNS_GOAPWorldState = {}

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

    if npcIsoPlayer:getHealth() then 
        worldState.isHealthLow = (npcSurvivor.healthThreshold and npcIsoPlayer:getHealth() < npcSurvivor.healthThreshold) or (npcIsoPlayer:getHealth() < 30)
    else
        worldState.isHealthLow = false
    end

    return worldState
end

return PZNS_GOAPWorldState;