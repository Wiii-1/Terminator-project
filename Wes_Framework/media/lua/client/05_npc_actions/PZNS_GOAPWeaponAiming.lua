local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WeaponAiming = require("05_npc_actions/PZNS_WeaponAiming")

local PZNS_GOAPWeaponAiming = {}
PZNS_GOAPWeaponAiming.name = "PZNS_GOAP_Weapon_Aiming"
PZNS_GOAPWeaponAiming.preconditions = { isWeaponEquipped = true, isTargetVisible = true }
PZNS_GOAPWeaponAiming.effects = { hasWeaponAimed = true }
PZNS_GOAPWeaponAiming.cost = 6.0
PZNS_GOAPWeaponAiming.isQueued = true

function PZNS_GOAPWeaponAiming:activate(npcSurvivor)
	npcSurvivor.aimTarget = getSpecificPlayer(0)
	if npcSurvivor.aimTarget ~= nil then
		-- WIP - Cows: Should add a check to see if enemy is in range...
		PZNS_WeaponAiming(npcSurvivor) -- Cows: Aim before attacking
	end
end

return PZNS_GOAPWeaponAiming
