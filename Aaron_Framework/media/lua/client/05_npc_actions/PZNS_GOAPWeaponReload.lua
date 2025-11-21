<<<<<<< HEAD
local PZNS_WeaponReload = require("05_npc_actions/PZNS_WeaponReload") 
=======
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
<<<<<<< HEAD
local PZNS_WeaponReload = require("02_mod_utils/PZNS_WeaponReload") 
>>>>>>> 6dcdeba (wrapped actions for GOAP Planner compatibility)
=======
local PZNS_WeaponReload = require("05_npc_actions/PZNS_WeaponReload") 
>>>>>>> 0050aad (still fixing)

local PZNS_GOAPWeaponReload = {}
PZNS_GOAPWeaponReload.name = "PZNS_GOAP_Weapon_Reload"
PZNS_GOAPWeaponReload.preconditions = {isWeaponEquipped = true, isWeaponLowOnAmmo = true, hasAmmoAvailable = true}
PZNS_GOAPWeaponReload.effects = {hasWeaponReloaded = true}
<<<<<<< HEAD
PZNS_GOAPWeaponReload.cost = 4.0

function PZNS_GOAPWeaponReload:activate(npcSurvivor, weaponItem)
    PZNS_WeaponReload.reloadWeapon(npcSurvivor, weaponItem)
=======
PZNS_GOAPWeaponReload.cost = 1.0

function PZNS_GOAPWeaponReload:activate(npcSurvivor, weaponItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_WeaponReload.reloadWeapon(npcSurvivor, weaponItem)
>>>>>>> 6dcdeba (wrapped actions for GOAP Planner compatibility)
end

return PZNS_GOAPWeaponReload;
