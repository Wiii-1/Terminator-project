local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local PZNS_GOAPPlanner = require("07_npc_ai/PZNS_GOAPPlanner")
local PZNS_GOAPGunMagazine = require("05_npc_actions/PZNS_GOAPGunMagazine")
local PZNS_GOAPPickUpWeapon = require("05_npc_actions/PZNS_GOAPPickUpWeapon")
local PZNS_GOAPRunTo = require("05_npc_actions/PZNS_GOAPRunTo")
local PZNS_GOAPScavenge = require("05_npc_actions/PZNS_GOAPScavenge")
local PZNS_GOAPSwitchWeapon = require("05_npc_actions/PZNS_GOAPSwitchWeapon")
local PZNS_GOAPWalkTo = require("05_npc_actions/PZNS_GOAPWalkTo")
local GOAP_WeaponAttack = require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponAttack")
local PZNS_GOAPWeaponEquip = require("05_npc_actions/PZNS_GOAPWeaponEquip")
local PZNS_GOAP_WeaponReload = require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponReload")
local GOAPHuntPlayer = require("05_npc_actions/GOAP_Actions/GOAPHuntPlayer")

local PZNS_GOAP_WeaponAiming = require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponAiming")
local PZNS_GOAP_WeaponRangedAttack = require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponRangedAttack")

TICK = 0

--- Execute a single action module. Try common function names; if none exist, apply effects instantly.
local function executeAction(npc, act, ws)
	if not act then
		return false
	end

	-- prefer asynchronous or coroutine-style action functions if present
	local runFn = act.perform or act.run or act.execute or act.start
	if type(runFn) == "function" then
		local ok, res = pcall(runFn, npc, ws) -- action should handle its own timing/state
		if ok then
			-- action claims success (true) or failure (false) or nil -> assume success
			return res ~= false
		else
			print("PZNS_JobTerminator: action error:", tostring(res))
			return false
		end
	end

	-- fallback: apply effects directly to worldstate (instant)
	if type(act.effects) == "table" then
		for k, v in pairs(act.effects) do
			ws[k] = v
		end
		return true
	end

	return false
end

--- @param npcSurvivor PZNS_NPCSurvivor
--- @param targetID string
function PZNS_JobTerminator(npcSurvivor, targetID)
	-- Build GOAP worldstate and request plan (auto-select best goal)
	local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor, { heavyScan = true })
	if not ws then
		print("PZNS_JobTerminator: failed to build world state")
		return
	end

	-- if TICK == 0 then
	-- 	PZNS_GOAP_WeaponReload.perform(npcSurvivor)
	-- 	print("done")
	-- 	TICK = TICK + 1
	-- end
	-- print("aaaa")
	-- PZNS_GOAP_WeaponAiming.perform(npcSurvivor)
	-- PZNS_GOAP_WeaponRangedAttack.perform(npcSurvivor)
	-- PZNS_GOAP_WeaponAiming.perform(npcSurvivor)
	-- GOAP_WeaponAiming.perform(npcSurvivor)

	-- print("job done")
	--
	-- npcSurvivor.aimTarget = getSpecificPlayer(0)
	-- if npcSurvivor.aimTarget ~= nil then
	-- 	-- WIP - Cows: Should add a check to see if enemy is in range...
	-- 	PZNS_WeaponAiming.PZNS_WeaponAiming(npcSurvivor) -- Cows: Aim before attacking
	-- else
	-- 	print("No aim")
	-- end

	-- PZNS_WeaponAiming.PZNS_WeaponAiming(npcSurvivor)

	local plan = PZNS_GOAPPlanner.planForNPC(npcSurvivor)
	if not plan then
		-- no plan found; you can fallback to other behaviors here
		-- e.g., follow player if in range, wander otherwise
		-- if isTerminatorInFollowRange(npcIsoPlayer, targetIsoPlayer) then
		-- continue following (existing follow job/logic)
		-- PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, "Follow")
		-- end
		print("No plan :(( ")
		return
	end

	-- execute plan steps in order (blocking/synchronous example)
	for i, act in ipairs(plan) do
		local success = executeAction(npcSurvivor, act, ws)
		if not success then
			print("PZNS_JobTerminator: action failed - will replan next tick")
			return -- stop and let next tick replan
		end
		-- update worldstate after successful action (many actions already modify world state)
		if type(act.effects) == "table" then
			for k, v in pairs(act.effects) do
				ws[k] = v
			end
		end
	end

	-- plan completed -> NPC achieved goal; you may reset job or choose next behavior
end

return PZNS_JobTerminator
