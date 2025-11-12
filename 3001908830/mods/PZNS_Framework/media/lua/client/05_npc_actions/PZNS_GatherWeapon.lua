local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

--- Gather a weapon from the environment or inventory
---@param npcSurvivor PZNS_NPCSurvivor
---@param preferredWeaponType string "ranged" or "melee" (default: "ranged")
function PZNS_GatherWeapon(npcSurvivor, preferredWeaponType)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return
    end
    
    preferredWeaponType = preferredWeaponType or "ranged"
    
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    
    -- Check if already has appropriate weapon
    local currentWeapon = npcIsoPlayer:getPrimaryHandItem()
    if currentWeapon and currentWeapon:IsWeapon() then
        if preferredWeaponType == "ranged" and currentWeapon:isRanged() then
            print("[GatherWeapon] Already has ranged weapon")
            return
        elseif preferredWeaponType == "melee" and not currentWeapon:isRanged() then
            print("[GatherWeapon] Already has melee weapon")
            return
        end
    end
    
    -- Try to equip from inventory first
    local inventory = npcIsoPlayer:getInventory()
    local items = inventory:getItems()
    
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:IsWeapon() then
            if preferredWeaponType == "ranged" and item:isRanged() then
                npcIsoPlayer:setPrimaryHandItem(item)
                npcSurvivor.lastEquippedRangeWeapon = item
                print("[GatherWeapon] Equipped ranged weapon from inventory:", item:getName())
                return
            elseif preferredWeaponType == "melee" and not item:isRanged() then
                npcIsoPlayer:setPrimaryHandItem(item)
                npcSurvivor.lastEquippedMeleeWeapon = item
                print("[GatherWeapon] Equipped melee weapon from inventory:", item:getName())
                return
            end
        end
    end
    
    -- If no weapon in inventory, spawn one (for testing/gameplay purposes)
    local weaponID = preferredWeaponType == "ranged" and "Base.Pistol" or "Base.BaseballBat"
    PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, weaponID)
    
    -- If ranged weapon, load it
    if preferredWeaponType == "ranged" then
        PZNS_UtilsNPCs.PZNS_SetLoadedGun(npcSurvivor)
        PZNS_UtilsNPCs.PZNS_AddItemToInventoryNPCSurvivor(npcSurvivor, "Base.9mmClip")
        PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(npcSurvivor, "Base.Bullets9mm", 30)
    end
    
    print("[GatherWeapon] Equipped new weapon:", weaponID)
end

return { PZNS_GatherWeapon = PZNS_GatherWeapon }
