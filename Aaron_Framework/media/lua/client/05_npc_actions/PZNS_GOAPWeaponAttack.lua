local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
<<<<<<< HEAD
local PZNS_WeaponAttack = require("05_npc_actions/PZNS_WeaponAttack")
=======
local PZNS_WeaponAttack = require("02_mod_utils/PZNS_WeaponAttack")
>>>>>>> 3fb9774 (check)

local PZNS_GOAPWeaponAttack = {}
PZNS_GOAPWeaponAttack.name = "PZNS_GOAP_Weapon_Attack"
PZNS_GOAPWeaponAttack.preconditions = {hasWeaponAimed = true, isTargetInRange = true, isWeaponEquipped = true}
PZNS_GOAPWeaponAttack.effects = {hasAttackedTarget = true}
<<<<<<< HEAD
PZNS_GOAPWeaponAttack.cost = 5.0

function PZNS_GOAPWeaponAttack:activate(npcSurvivor, targetIsoObject)
    PZNS_WeaponAttack.attackTarget(npcSurvivor, targetIsoObject)
=======
PZNS_GOAPWeaponAttack.cost = 1.0

function PZNS_GOAPWeaponAttack:activate(npcSurvivor, targetIsoObject)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_WeaponAttack.attackTarget(npcSurvivor, targetIsoObject)
>>>>>>> 3fb9774 (check)
end

return PZNS_GOAPWeaponAttack;