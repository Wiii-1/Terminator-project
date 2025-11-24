local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WeaponReload = require("05_npc_actions/PZNS_WeaponReload") 

local PZNS_GOAPWeaponReload = {}
PZNS_GOAPWeaponReload.name = "PZNS_GOAP_Weapon_Reload"
PZNS_GOAPWeaponReload.preconditions = {isWeaponEquipped = true, isWeaponLowOnAmmo = true, hasAmmoAvailable = true}
PZNS_GOAPWeaponReload.effects = {hasWeaponReloaded = true}
PZNS_GOAPWeaponReload.cost = 1.0

function PZNS_GOAPWeaponReload:activate(npcSurvivor, weaponItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_WeaponReload.reloadWeapon(npcSurvivor, weaponItem)
end

return PZNS_GOAPWeaponReload;
