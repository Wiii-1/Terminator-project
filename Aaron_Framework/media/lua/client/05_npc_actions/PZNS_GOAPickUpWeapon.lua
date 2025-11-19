local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_NPCPickUpWeapon = require("05_npc_actions/PZNS_NPCPickUpWeapon")

local PZNS_GOAPickUpWeapon = {}
PZNS_GOAPickUpWeapon.name = "PZNS_GOAP_Pick_Up_Weapon"
PZNS_GOAPickUpWeapon.preconditions = {isWeaponAvailable = true}
PZNS_GOAPickUpWeapon.effects = {hasWeaponPickedUp = true}
PZNS_GOAPickUpWeapon.cost = 1.0

function PZNS_GOAPickUpWeapon:activate(npcSurvivor, weaponItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_NPCPickUpWeapon.execute(npcSurvivor, weaponItem)
end

return PZNS_GOAPickUpWeapon;