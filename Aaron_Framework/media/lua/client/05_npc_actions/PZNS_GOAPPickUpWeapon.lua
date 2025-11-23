local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCPickUpWeapon = require("05_npc_actions/PZNS_NPCPickUpWeapon")

local PZNS_GOAPPickUpWeapon = {}
PZNS_GOAPPickUpWeapon.name = "PZNS_GOAP_Pick_Up_Weapon"
PZNS_GOAPPickUpWeapon.preconditions = {isWeaponAvailable = true}
PZNS_GOAPPickUpWeapon.effects = {hasWeaponPickedUp = true}
PZNS_GOAPPickUpWeapon.cost = 3.0

function PZNS_GOAPPickUpWeapon:activate(npcSurvivor, weaponItem)
    PZNS_NPCPickUpWeapon.execute(npcSurvivor, weaponItem)
end

return PZNS_GOAPPickUpWeapon;