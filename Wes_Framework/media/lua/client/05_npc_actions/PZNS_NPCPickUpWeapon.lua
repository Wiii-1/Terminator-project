local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");

local PZNS_NPCPickUpWeapon = {};

local function canNPCPickUpWeapon(npcSurvivor, weaponItem)
    -- Check if NPC and weapon item are valid
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) or weaponItem == nil then
        return false;
    end

    -- Check if NPC already has the weapon
    local inventory = npcSurvivor.npcIsoPlayerObject:getInventory();
    if inventory:contains(weaponItem) then
        return false;  -- NPC already has the weapon
    end

    return true;  -- NPC can pick up the weapon
end

PZNS_NPCPickUpWeapon.canNPCPickUpWeapon = canNPCPickUpWeapon;

return PZNS_NPCPickUpWeapon;