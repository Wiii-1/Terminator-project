local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
<<<<<<< HEAD
<<<<<<< HEAD
local PZNS_GunMagazine = require("05_npc_actions/PZNS_GunMagazine")
=======
local PZNS_GunMagasine = require("02_mod_utils/PZNS_GunMagasine")
>>>>>>> 3fb9774 (check)
=======
local PZNS_GunMagazine = require("05_npc_actions/PZNS_GunMagazine")
>>>>>>> 0050aad (still fixing)

local PZNS_GOAPGunMagazine = {}
PZNS_GOAPGunMagazine.name = "PZNS_GOAP_Gun_Magazine"
PZNS_GOAPGunMagazine.preconditions = {isGunMagazineAvailable = true}
PZNS_GOAPGunMagazine.effects = {hasGunMagazineLoaded = true}
PZNS_GOAPGunMagazine.cost = 1.0

function PZNS_GOAPGunMagazine:activate(npcSurvivor, weaponItem, magazineItem)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return false
    end

<<<<<<< HEAD
<<<<<<< HEAD
    return PZNS_GunMagazine.loadMagazineIntoWeapon(npcSurvivor, weaponItem, magazineItem)
=======
    return PZNS_GunMagasine.loadMagazineIntoWeapon(npcSurvivor, weaponItem, magazineItem)
>>>>>>> 3fb9774 (check)
=======
    return PZNS_GunMagazine.loadMagazineIntoWeapon(npcSurvivor, weaponItem, magazineItem)
>>>>>>> 0050aad (still fixing)
end

return PZNS_GOAPGunMagazine;