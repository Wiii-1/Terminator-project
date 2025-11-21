local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_GunMagazine = require("05_npc_actions/PZNS_GunMagazine")

local PZNS_GOAPGunMagazine = {}
PZNS_GOAPGunMagazine.name = "PZNS_GOAP_Gun_Magazine"
PZNS_GOAPGunMagazine.preconditions = {isGunMagazineAvailable = true}
PZNS_GOAPGunMagazine.effects = {hasGunMagazineLoaded = true}
PZNS_GOAPGunMagazine.cost = 1.0

function PZNS_GOAPGunMagazine:activate(npcSurvivor, weaponItem, magazineItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

    return PZNS_GunMagazine.loadMagazineIntoWeapon(npcSurvivor, weaponItem, magazineItem)
end

return PZNS_GOAPGunMagazine;