local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WeaponAiming = require("05_npc_actions/PZNS_WeaponAiming")

local PZNS_GOAPWeaponAiming = {}
PZNS_GOAPWeaponAiming.name = "PZNS_GOAP_Weapon_Aiming"
PZNS_GOAPWeaponAiming.preconditions = {isWeaponEquipped = true, isTargetVisible = true}
PZNS_GOAPWeaponAiming.effects = {hasWeaponAimed = true}
PZNS_GOAPWeaponAiming.cost = 1.0
PZNS_GOAPWeaponAiming.isQueued = true

function PZNS_GOAPWeaponAiming:activate(npcSurvivor, targetIsoObject)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_WeaponAiming.aimAtTarget(npcSurvivor, targetIsoObject)
end

return PZNS_GOAPWeaponAiming;
