local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCSwitchWeapon = require("05_npc_actions/PZNS_NPCSwitchWeapon")

local PZNS_GOAPSwitchWeapon = {}
PZNS_GOAPSwitchWeapon.name = "PZNS_GOAP_Switch_Weapon"
PZNS_GOAPSwitchWeapon.preconditions = {isWeaponAvailable = true}
PZNS_GOAPSwitchWeapon.effects = {hasWeaponEquipped = true}
PZNS_GOAPSwitchWeapon.cost = 1.0

function PZNS_GOAPSwitchWeapon:activate(npcSurvivor, weaponItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_NPCSwitchWeapon.switchNPCWeapon(npcSurvivor, weaponItem)
end

return PZNS_GOAPSwitchWeapon;