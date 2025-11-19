local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils");
local PZNS_NPCEquipWeapon = require("05_npc_actions/PZNS_NPCEquipWeapon");

local PZNS_NPCSwitchWeapon = {};

local function isWeaponBroken (weaponItem)
    if not weaponItem then return true end

    if weaponItem.getCondition then
        if weaponItem:getCondition() <= 0 then
            return true
        end
    end

    return false
end

local function switchNPCWeapon(npcSurvivor, weaponItem)
    -- Check if NPC and weapon item are valid
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) or weaponItem == nil then
        return false;
    end

    if not PZNS_WorldUtils.PZNS_IsItemWeapon(weaponItem) then
        return false;  -- Not a valid weapon item
    end

    local hand = npcSurvivor.npcIsoPlayerObject:getPrimaryHandItem();-- wii: call lng to ng primary weapon sa kamay

    local inventory = npcSurvivor.npcIsoPlayerObject:getInventory(); -- wii: call lng to ng inventory

    -- wii: check if yung weapon is valid yung weapon
    if weaponItem == nil then
        return false;  -- Invalid weapon item
    end

    -- wii: check lng to ung sira yung weapon or not
    if isWeaponBroken(hand) then
        local inventory = npcSurvivor.npcIsoPlayerObject:getPrimaryHandItem();
        for i=0, inventory:getItems():size()-1 do
            local item = inventory:getItems():get(i);
            if PZNS_WorldUtils.PZNS_IsItemWeapon(item) and not isWeaponBroken(item) then
                npcSurvivor.npcIsoPlayerObject:setPrimaryHandItem(item);
                return true;  -- Switched to a non-broken weapon
            end
        end
        return false;  -- Cannot switch to a broken weapon
    end

    -- Check if NPC has the weapon
    if inventory:contains(weaponItem) then
        if PZNS_NPCEquipWeapon.equipWeapon then
            PZNS_NPCEquipWeapon.equipWeapon(npcSurvivor, weaponItem);
        elseif PZNS_NPCEquipWeapon.execute then
            PZNS_NPCEquipWeapon.execute(npcSurvivor, weaponItem);
        else 
            npcSurvivor.npcIsoPlayerObject:setPrimaryHandItem(weaponItem);
        end

        return true;
    end

    return false;  -- NPC does not have the weapon to switch to
end
        


PZNS_NPCSwitchWeapon.switchNPCWeapon = switchNPCWeapon;

return PZNS_NPCSwitchWeapon;