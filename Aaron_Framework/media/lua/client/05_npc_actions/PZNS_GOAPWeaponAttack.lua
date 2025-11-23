local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WeaponAttack = require("05_npc_actions/PZNS_WeaponAttack")

local PZNS_GOAPWeaponAttack = {}
PZNS_GOAPWeaponAttack.name = "PZNS_GOAP_Weapon_Attack"
PZNS_GOAPWeaponAttack.preconditions = {hasWeaponAimed = true, isTargetInRange = true, isWeaponEquipped = true}
PZNS_GOAPWeaponAttack.effects = {hasAttackedTarget = true}
PZNS_GOAPWeaponAttack.cost = 5.0

function PZNS_GOAPWeaponAttack:activate(npcSurvivor, targetIsoObject)
    PZNS_WeaponAttack.attackTarget(npcSurvivor, targetIsoObject)
end

return PZNS_GOAPWeaponAttack;