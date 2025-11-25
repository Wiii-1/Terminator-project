local PZNS_WeaponReload = require("05_npc_actions/PZNS_WeaponReload")

local PZNS_GOAPWeaponReload = {}
PZNS_GOAPWeaponReload.name = "PZNS_GOAP_Weapon_Reload"
PZNS_GOAPWeaponReload.preconditions = { isWeaponEquipped = true, isAmmoLow = false, hasAmmoInChamber = false }
PZNS_GOAPWeaponReload.effects = { hasWeaponReloaded = true }
PZNS_GOAPWeaponReload.cost = 4.0

function PZNS_GOAPWeaponReload:activate(npcSurvivor, weaponItem)
	PZNS_WeaponReload.reloadWeapon(npcSurvivor, weaponItem)
end

return PZNS_GOAPWeaponReload

