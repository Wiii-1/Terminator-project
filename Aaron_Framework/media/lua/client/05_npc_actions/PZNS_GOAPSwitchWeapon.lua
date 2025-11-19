local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCSwitchWeapon = require("05_npc_actions/PZNS_NPCSwitchWeapon")

local PZNS_GOAPSwitchWeapon = {}
PZNS_GOAPSwitchWeapon.name = "PZNS_GOAP_Switch_Weapon"
PZNS_GOAPSwitchWeapon.preconditions = {isWeaponAvailable = true}
PZNS_GOAPSwitchWeapon.effects = {hasWeaponEquipped = true}
<<<<<<< HEAD
PZNS_GOAPSwitchWeapon.cost = 2.0

function PZNS_GOAPSwitchWeapon:activate(npcSurvivor, weaponItem)
    PZNS_NPCSwitchWeapon.switchNPCWeapon(npcSurvivor, weaponItem)
=======
PZNS_GOAPSwitchWeapon.cost = 1.0

function PZNS_GOAPSwitchWeapon:activate(npcSurvivor, weaponItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_NPCSwitchWeapon.switchNPCWeapon(npcSurvivor, weaponItem)
>>>>>>> 3fb9774 (check)
end

return PZNS_GOAPSwitchWeapon;