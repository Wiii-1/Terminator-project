local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_GOAP_Actions = require("05_npc_actions/PZNS_GOAP_Actions")

local GOAP_WeaponReload = {}
GOAP_WeaponReload.name = "WeaponReload_Action"

setmetatable(GOAP_WeaponReload, { __index = PZNS_GOAP_Actions })

function GOAP_WeaponReload.isValid()
	return true
end

function GOAP_WeaponReload.get_Cost()
	return 7
end

function GOAP_WeaponReload.get_preconditions()
	return {
		hasWeaponEquipped = true,
		isWeaponRanged = true,
		hasAmmoInChamber = false,
	}
end

function GOAP_WeaponReload.get_effects()
	return { hasAmmoInChamber = true }
end

-- ============================================
-- GOAP_WeaponReload.perform() WITH DEBUG OUTPUT
-- ============================================

local DEBUG_RELOAD = true -- Toggle debug output

function GOAP_WeaponReload.perform(npcSurvivor)
	-- ========== DEBUG: FUNCTION START ==========
	if DEBUG_RELOAD then
		print("\n[RELOAD] ===== WEAPON RELOAD PERFORM START =====")
		print("[RELOAD] NPC: " .. (npcSurvivor.name or "unknown"))
	end

	-- Get NPC and weapon
	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
	local npcHandItem = npcIsoPlayer:getPrimaryHandItem()
	local ammoType = npcHandItem:getAmmoType()

	-- ========== DEBUG: WEAPON INFO ==========
	if DEBUG_RELOAD then
		print("[RELOAD] Weapon: " .. (npcHandItem:getName() or "unknown"))
		print("[RELOAD] Ammo Type: " .. (ammoType or "none"))
	end

	-- Check reload conditions
	local ammoCount = 0
	if ammoType then
		local npc_inventory = npcIsoPlayer:getInventory()
		ammoCount = npc_inventory:getItemCountRecurse(ammoType)
	end

	-- ========== DEBUG: RELOAD CONDITION CHECK ==========
	if DEBUG_RELOAD then
		print("[RELOAD] Current ammo in gun: " .. npcHandItem:getCurrentAmmoCount())
		print("[RELOAD] Ammo in inventory: " .. ammoCount)
		print("[RELOAD] Magazine in gun: " .. tostring(npcHandItem:isContainsClip()))
		print("[RELOAD] Magazine type: " .. (npcHandItem:getMagazineType() or "none"))
	end

	if
		(npcHandItem:getCurrentAmmoCount() == 0 and ammoCount > 0)
		or (npcHandItem:getMagazineType() ~= nil and npcHandItem:isContainsClip() == false)
	then
		-- ========== DEBUG: RELOAD CONDITIONS MET ==========
		if DEBUG_RELOAD then
			print("[RELOAD] ✓ RELOAD CONDITIONS MET")
			print("[RELOAD] Gun empty: " .. tostring(npcHandItem:getCurrentAmmoCount() == 0))
			print("[RELOAD] Has ammo: " .. tostring(ammoCount > 0))
			print("[RELOAD] Magazine-fed: " .. tostring(npcHandItem:getMagazineType() ~= nil))
			print("[RELOAD] Magazine missing: " .. tostring(not npcHandItem:isContainsClip()))
		end

		-- Stop any attacks
		npcIsoPlayer:NPCSetAttack(false)

		-- Get action queue info
		local actionsCount = PZNS_UtilsNPCs.PZNS_GetNPCActionsQueuedCount(npcSurvivor)
		local actionQueue = ISTimedActionQueue.getTimedActionQueue(npcIsoPlayer)
		local lastAction = actionQueue.queue[#actionQueue.queue]

		-- ========== DEBUG: ACTION QUEUE ==========
		if DEBUG_RELOAD then
			print("[RELOAD] Actions queued: " .. actionsCount)
			if lastAction then
				print("[RELOAD] Last action type: " .. (lastAction.Type or "unknown"))
			else
				print("[RELOAD] No actions in queue yet")
			end
		end

		-- Check for magazine-based reload
		local magazineType = npcHandItem:getMagazineType()

		if magazineType ~= nil then
			-- ========== DEBUG: MAGAZINE-BASED RELOAD ==========
			if DEBUG_RELOAD then
				print("[RELOAD] Magazine-based weapon detected")
				print("[RELOAD] Magazine type: " .. magazineType)
			end

			-- If too many actions queued, clear them
			if actionsCount > 3 then
				if DEBUG_RELOAD then
					print("[RELOAD] ⚠️  Too many actions queued (" .. actionsCount .. "), clearing...")
				end
				PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor)
			end

			local npc_inventory = npcIsoPlayer:getInventory()
			local bestMagazine = npcHandItem:getBestMagazine(npcIsoPlayer)
			local magazine = npc_inventory:getFirstTypeRecurse(magazineType)

			-- ========== DEBUG: MAGAZINE SEARCH ==========
			if DEBUG_RELOAD then
				print("[RELOAD] Best magazine found: " .. tostring(bestMagazine ~= nil))
				print("[RELOAD] Magazine in inventory: " .. tostring(magazine ~= nil))
			end

			if bestMagazine then
				-- ========== DEBUG: INSERT MAGAZINE ==========
				if DEBUG_RELOAD then
					print("[RELOAD] ✓ Using best magazine")
				end

				if lastAction then
					-- Check last action type
					if lastAction.Type ~= "ISLoadBulletsInMagazine" and actionsCount > 1 then
						if DEBUG_RELOAD then
							print("[RELOAD]  Clearing queue, last action was: " .. lastAction.Type)
						end
						PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor)
					end
				end

				-- Queue insert magazine action
				if DEBUG_RELOAD then
					print("[RELOAD] Queueing: ISInsertMagazine")
				end
				local insertMagAction = ISInsertMagazine:new(npcIsoPlayer, npcHandItem, magazine)
				PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, insertMagAction)
			else
				-- ========== DEBUG: RELOAD MAGAZINE ==========
				if DEBUG_RELOAD then
					print("[RELOAD] No best magazine, performing reload sequence")
				end

				-- Eject current magazine if present
				if npcHandItem:isContainsClip() then
					if DEBUG_RELOAD then
						print("[RELOAD] Queueing: ISEjectMagazine")
					end
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
					-- ========== DEBUG: BULLET CALCULATION ==========
					if DEBUG_RELOAD then
						print("[RELOAD] Total bullets: " .. bullets)
						print("[RELOAD] Magazine capacity: " .. npcHandItem:getMaxAmmo())
					end

					-- Calculate how many bullets to load
					if bullets % npcHandItem:getMaxAmmo() == 0 then
						count = npcHandItem:getMaxAmmo()
						bullets = bullets - npcHandItem:getMaxAmmo()
					else
						count = bullets
					end

					-- ========== DEBUG: LOADING ==========
					if DEBUG_RELOAD then
						print("[RELOAD] Queueing: ISLoadBulletsInMagazine (" .. count .. " bullets)")
						print("[RELOAD] Remaining bullets after: " .. bullets)
					end

					local reloadMagAction = ISLoadBulletsInMagazine:new(npcIsoPlayer, magazine, count)
					PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, reloadMagAction)
				else
					if DEBUG_RELOAD then
						print("[RELOAD] ✗ No magazine found in inventory!")
					end
				end
			end
		else
			-- ========== DEBUG: AMMO-BASED RELOAD ==========
			if DEBUG_RELOAD then
				print("[RELOAD] Ammo-based weapon (not magazine-fed)")
				print("[RELOAD] Queueing: ISReloadWeaponAction")
			end
			ISTimedActionQueue.add(ISReloadWeaponAction:new(npcIsoPlayer, npcHandItem))
		end
	else
		-- ========== DEBUG: RELOAD CONDITIONS NOT MET ==========
		if DEBUG_RELOAD then
			print("[RELOAD] ✗ RELOAD CONDITIONS NOT MET")
			print("[RELOAD] Gun empty: " .. tostring(npcHandItem:getCurrentAmmoCount() == 0))
			print("[RELOAD] Has ammo: " .. tostring(ammoCount > 0))
		end
	end

	-- ========== DEBUG: FUNCTION END ==========
	if DEBUG_RELOAD then
		print("[RELOAD] ===== WEAPON RELOAD PERFORM END =====\n")
	end

	return true
end

-- ============================================
-- HELPER: Quick Test for Reload Logic
-- ============================================

function GOAP_WeaponReload.testReloadCondition(npcSurvivor)
	if DEBUG_RELOAD then
		print("\n[RELOAD TEST] ===== TESTING RELOAD CONDITION =====")
	end

	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
	local npcHandItem = npcIsoPlayer:getPrimaryHandItem()

	if not npcHandItem then
		if DEBUG_RELOAD then
			print("[RELOAD TEST] ✗ No weapon in hand")
		end
		return false
	end

	local ammoType = npcHandItem:getAmmoType()
	local npc_inventory = npcIsoPlayer:getInventory()
	local ammoCount = npc_inventory:getItemCountRecurse(ammoType)

	local conditionA = npcHandItem:getCurrentAmmoCount() == 0 and ammoCount > 0
	local conditionB = npcHandItem:getMagazineType() ~= nil and npcHandItem:isContainsClip() == false

	if DEBUG_RELOAD then
		print("[RELOAD TEST] Current ammo: " .. npcHandItem:getCurrentAmmoCount())
		print("[RELOAD TEST] Inventory ammo: " .. ammoCount)
		print("[RELOAD TEST] Condition A (empty + has ammo): " .. tostring(conditionA))
		print("[RELOAD TEST] Condition B (magazine-based + no clip): " .. tostring(conditionB))
		print("[RELOAD TEST] Should reload: " .. tostring(conditionA or conditionB))
		print("[RELOAD TEST] =========================================\n")
	end

	return conditionA or conditionB
end

return GOAP_WeaponReload

-- ============================================
-- USAGE EXAMPLES
-- ============================================

--[[
-- In your action execution code:

-- Enable/disable debug
DEBUG_RELOAD = true  -- or false to disable

-- Call reload
GOAP_WeaponReload.perform(npc)

-- Test reload condition without executing
local shouldReload = GOAP_WeaponReload.testReloadCondition(npc)
if shouldReload then
	print("Weapon needs reload!")
end
]]

-- get_Cost
-- get_preconditions
-- get_effects
-- perform

-- Add to PZNS_GOAP_WorldState
-- isWeaponRanged
-- handItem
-- ammoCount - change isAmmoLow to ammoCount
--
