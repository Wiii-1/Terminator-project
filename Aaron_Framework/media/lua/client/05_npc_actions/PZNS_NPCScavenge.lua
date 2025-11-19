local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils");

local PZNS_Scavenge = {};

local shotgunTypes = {
    ["Base.Shotgun"] = true,
    ["Base.ShotgunSawedOff"] = true,
    ["Base.ShotgunDoubleBarrel"] = true,
    ["Base.ShotgunHunting"] = true,
}

local shotgunAmmoTypes = {
    ["Base.ShotgunShells"] = true,
    ["Base.ShotgunShellsSlug"] = true,
}

local function isShotgunWeapon(weaponItem)
    if not weaponItem then return false end

    local weaponType = weaponItem:getType()
    if shotgunTypes[weaponType] then
        return true
    end

    return false
end

local function isShotgunAmmo(ammoItem)
    if not ammoItem then return false end

    local ammoType = ammoItem:getType()
    if shotgunAmmoTypes[ammoType] then
        return true
    end

    return false
end

local function findItemInInventoryOfTypes(npcSurvivor, itemTypesTable)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return nil
    end

    local inventory = npcSurvivor.npcIsoPlayerObject:getInventory();
    for i=0, inventory:getItems():size()-1 do
        local item = inventory:getItems():get(i)
        if itemTypesTable[item:getType()] then
            return item
        end
    end

    return nil
end

local function findNearestItemOnMapOfTypes(npcSurvivor, itemTypesTable, searchRadius)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return nil
    end

    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject;
    local npcX = npcIsoPlayer:getX();
    local npcY = npcIsoPlayer:getY();
    local nearestItem = nil;
    local nearestDistanceSq = searchRadius * searchRadius;

    local itemsOnMap = PZNS_WorldUtils.PZNS_GetAllItemsOnMap();
    for _, item in ipairs(itemsOnMap) do
        if itemTypesTable[item:getType()] then
            local itemX = item:getX();
            local itemY = item:getY();
            local dx = itemX - npcX;
            local dy = itemY - npcY;
            local distanceSq = dx * dx + dy * dy;

            if distanceSq < nearestDistanceSq then
                nearestItem = item;
                nearestDistanceSq = distanceSq;
            end
        end
    end

    return nearestItem
end

local function isDesiredShotgunOrAmmo(npcSurvivor, item)
    if isShotgunWeapon(item) then
        local hasShotgun = findItemInInventoryOfTypes(npcSurvivor, shotgunTypes)
        if not hasShotgun then
            return true
        end
    elseif isShotgunAmmo(item) then
        local hasShotgun = findItemInInventoryOfTypes(npcSurvivor, shotgunTypes)
        if hasShotgun then
            return true
        end
    end
    return false
end

local function canNPCScavengeItem(npcSurvivor, item)
    -- Check if NPC and item are valid
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) or item == nil then
        return false;
    end

    -- Check if NPC already has the item
    local inventory = npcSurvivor.npcIsoPlayerObject:getInventory();
    if inventory:contains(item) then
        return false;  -- NPC already has the item
    end

    if not PZNS_Scavenge.isDesiredShotgunOrAmmo(npcSurvivor, item) then
        return false;  -- Item is not a desired shotgun or ammo
    end

    return true;  -- NPC can scavenge the item
end

PZNS_Scavenge.canNPCScavengeItem = canNPCScavengeItem;
PZNS_Scavenge.isDesiredShotgunOrAmmo = isDesiredShotgunOrAmmo;
PZNS_Scavenge.findNearestItemOnMapOfTypes = findNearestItemOnMapOfTypes;
PZNS_Scavenge.findItemInInventoryOfTypes = findItemInInventoryOfTypes;


return PZNS_Scavenge;