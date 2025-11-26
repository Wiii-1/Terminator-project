local PZNS_GOAP_Actions = require("05_npc_actions/PZNS_GOAP_Actions")
local PZNS_WeaponAiming = require("05_npc_actions/PZNS_WeaponAiming")

local GOAP_WeaponAiming = {}
GOAP_WeaponAiming.name = "WeaponAiming_Action"

setmetatable(GOAP_WeaponAiming, { __index = PZNS_GOAP_Actions })

function GOAP_WeaponAiming.isValid(npcSurvivor)
	return true
end

function GOAP_WeaponAiming.get_Cost()
	return 5
end

function GOAP_WeaponAiming.get_preconditions()
	return {
		isWeaponEquipped = true, --
		isWeaponRanged = true,
		isTargetVisible = true, -- Nees huntPlayer
		isWeaponAimed = false, -- precondition
		isTargetInAttackRange = true, -- ws
	}
end

function GOAP_WeaponAiming.get_effects()
	return { isWeaponAimed = true }
end

function GOAP_WeaponAiming.perform(npcSurvivor)
	npcSurvivor.aimTarget = getSpecificPlayer(0)
	local targetObject = npcSurvivor.aimTarget
	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject

	if targetObject == nil then
		if npcIsoPlayer:NPCGetAiming() == true then
			npcIsoPlayer:NPCSetAiming(false)
		end
		return false
	else
		npcIsoPlayer:faceThisObject(targetObject)
		npcIsoPlayer:NPCSetAiming(true)
	end
	return true
end

return GOAP_WeaponAiming
