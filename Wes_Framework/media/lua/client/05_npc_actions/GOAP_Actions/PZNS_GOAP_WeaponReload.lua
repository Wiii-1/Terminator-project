local PZNS_GOAP_Actions = require("05_npc_actions/PZNS_GOAP_Actions")
local PZNS_WeaponReload = require("05_npc_actions/PZNS_WeaponReload")

local GOAP_WeaponReload = {}
GOAP_WeaponReload.name = "WeaponReload_Action"

setmetatable(GOAP_WeaponReload, { __index = PZNS_GOAP_Actions })

function GOAP_WeaponReload.isValid()
	return true
end

function GOAP_WeaponReload.get_Cost()
	return 3
end

function GOAP_WeaponReload.get_preconditions()
	return {
		isWeaponEquipped = true, --
		isWeaponRanged = true,
		hasAmmoInChamber = false, -- action starter
	}
end

function GOAP_WeaponReload.get_effects()
	return { hasAmmoInChamber = true }
end

function GOAP_WeaponReload.perform(npcSurvivor)
	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
	local npcHandItem = npcIsoPlayer:getPrimaryHandItem()

	if not npcHandItem then
		return false
	end

	local ammoType = npcHandItem:getAmmoType()

	-- Check reload conditions
	local ammoCount = 0
	if ammoType then
		local npc_inventory = npcIsoPlayer:getInventory()
		ammoCount = npc_inventory:getItemCountRecurse(ammoType)
	end

	-- Check if reload is needed
	if
		(npcHandItem:getCurrentAmmoCount() == 0 and ammoCount > 0)
		or (npcHandItem:getMagazineType() ~= nil and npcHandItem:isContainsClip() == false)
	then
		-- Stop any attacks
		npcIsoPlayer:NPCSetAttack(false)
		-- Check for magazine-based reload
		local magazineType = npcHandItem:getMagazineType()
		if magazineType ~= nil then
			local npc_inventory = npcIsoPlayer:getInventory()
			local bestMagazine = npcHandItem:getBestMagazine(npcIsoPlayer)
			local magazine = npc_inventory:getFirstTypeRecurse(magazineType)

			if bestMagazine then
				if lastAction then
					if lastAction.Type ~= "ISLoadBulletsInMagazine" and actionsCount > 1 then
						PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor)
					end
				end

				-- Queue insert magazine action
				local insertMagAction = ISInsertMagazine:new(npcIsoPlayer, npcHandItem, magazine)
				PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, insertMagAction)
			else
				-- Eject current magazine if present
				if npcHandItem:isContainsClip() then
					local ejectMagAction = ISEjectMagazine:new(npcIsoPlayer, npcHandItem)
					PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, ejectMagAction)
				end

				-- Load bullets into magazine
				if magazine then
					local bullets = 0
					local count = 0
					if ammoType then
						bullets = npc_inventory:getItemCountRecurse(ammoType)
					end

					if bullets % npcHandItem:getMaxAmmo() == 0 then
						count = npcHandItem:getMaxAmmo()
						bullets = bullets - npcHandItem:getMaxAmmo()
					else
						count = bullets
					end

					local reloadMagAction = ISLoadBulletsInMagazine:new(npcIsoPlayer, magazine, count)
					PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, reloadMagAction)
				end
			end
		else
			ISTimedActionQueue.add(ISReloadWeaponAction:new(npcIsoPlayer, npcHandItem))
		end
	else
		return true
	end
	return true
end

return GOAP_WeaponReload
