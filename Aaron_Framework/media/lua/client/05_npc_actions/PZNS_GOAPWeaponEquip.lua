local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCEquipWeapon = require("05_npc_actions/PZNS_NPCSwitchWeapon")

local PZNS_GOAPWeaponEquip = {}

PZNS_GOAPWeaponEquip.name = "PZNS_GOAP_Weapon_Equip"
PZNS_GOAPWeaponEquip.preconditions = {isWeaponAvailable = true}
PZNS_GOAPWeaponEquip.effects = {hasWeaponEquipped = true}
PZNS_GOAPWeaponEquip.cost = 1.0

function PZNS_GOAPWeaponEquip:activate(npcSurvivor, weaponItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    if PZNS_NPCEquipWeapon.equipWeapon then
        return PZNS_NPCEquipWeapon.equipWeapon(npcSurvivor, weaponItem)
    elseif PZNS_NPCEquipWeapon.execute then
        return PZNS_NPCEquipWeapon.execute(npcSurvivor, weaponItem)
    end

    return false
end