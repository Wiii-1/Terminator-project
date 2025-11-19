local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCPickUpWeapon = require("05_npc_actions/PZNS_NPCPickUpWeapon")

local PZNS_GOAPPickUpWeapon = {}
PZNS_GOAPPickUpWeapon.name = "PZNS_GOAP_Pick_Up_Weapon"
PZNS_GOAPPickUpWeapon.preconditions = {isWeaponAvailable = true}
PZNS_GOAPPickUpWeapon.effects = {hasWeaponPickedUp = true}
<<<<<<< HEAD
PZNS_GOAPPickUpWeapon.cost = 3.0

function PZNS_GOAPPickUpWeapon:activate(npcSurvivor, weaponItem)
    PZNS_NPCPickUpWeapon.execute(npcSurvivor, weaponItem)
=======
PZNS_GOAPPickUpWeapon.cost = 1.0

function PZNS_GOAPPickUpWeapon:activate(npcSurvivor, weaponItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_NPCPickUpWeapon.execute(npcSurvivor, weaponItem)
>>>>>>> 3fb9774 (check)
end

return PZNS_GOAPPickUpWeapon;