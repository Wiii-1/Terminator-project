local PZNS_GOAP_Actions = require("05_npc_actions/PZNS_GOAP_Actions")
local PZNS_WeaponAttack = require("05_npc_actions/PZNS_WeaponAttack")
local PZNS_GeneralAI = require("07_npc_ai/PZNS_GeneralAI")

local GOAP_WeaponRangedAttack = {}
GOAP_WeaponRangedAttack.name = "WeaponRangedAttack_Action"

setmetatable(GOAP_WeaponRangedAttack, { __index = PZNS_GOAP_Actions })

function GOAP_WeaponRangedAttack.isValid(npcSurvivor)
	return true
end

function GOAP_WeaponRangedAttack.get_Cost()
	return 7
end

function GOAP_WeaponRangedAttack.get_preconditions()
	return {
		isWeaponEquipped = true, --
		isWeaponRanged = true, --
		isWeaponAimed = true, -- Needs isWeaponAimed
		hasAmmoInChamber = true, -- Needs Reload
		isTargetVisible = true, -- Needs huntplayer
		isTargetInAttackRange = true, -- Nees huntPlayer
	}
end

function GOAP_WeaponRangedAttack.get_effects()
	return { isTargetDead = true }
end

function GOAP_WeaponRangedAttack.perform(npcSurvivor)
	PZNS_GeneralAI.PZNS_IsNPCBusyCombat(npcSurvivor)

	return true
end

return GOAP_WeaponRangedAttack
