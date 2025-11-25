-- Wii: idk lng paano to sa storing part nakita ko lng din sa PZNS_UtilsNPCs 

local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");

local PZNS_NPCEquipWeapon = {};

local function equipWeapon(npcSurvivor, weaponItem)
    -- Check if NPC and weapon item are valid
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) or weaponItem == nil then
        return false;
    end

    local inventory = npcSurvivor.npcIsoPlayerObject:getInventory();

    -- Check if NPC already has the weapon
    if inventory:contains(weaponItem) then


        -- Equip the weapon if it's not already equipped
        if npcSurvivor.npcIsoPlayerObject:getPrimaryHandItem() ~= weaponItem then
            npcSurvivor.npcIsoPlayerObject:setPrimaryHandItem(weaponItem);
        end
        return true;  -- Weapon is already in inventory and equipped
    end

    return false;  -- NPC does not have the weapon
end

PZNS_NPCEquipWeapon.equipWeapon = equipWeapon;

return PZNS_NPCEquipWeapon;