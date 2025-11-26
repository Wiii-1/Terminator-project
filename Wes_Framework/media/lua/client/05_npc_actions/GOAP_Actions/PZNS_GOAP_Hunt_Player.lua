local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
-- movement wrappers (may be missing — safe pcall)
local okRun, PZNS_RunTo = pcall(require, "05_npc_actions/PZNS_RunTo")
local okWalk, PZNS_WalkTo = pcall(require, "05_npc_actions/PZNS_WalkTo")
local PZNS_WalkToo = require("05_npc_actions/PZNS_WalkTo")

local function tryCallMovement(mod, names, npcSurvivor, x, y, z)
	if not mod then
		return false
	end
	for _, name in ipairs(names) do
		local fn = mod[name]
		if type(fn) == "function" then
			local ok, res = pcall(fn, mod, npcSurvivor, x, y, z)
			if ok then
				return res ~= false
			end
			print("movement method error:", name, tostring(res))
			return false
		end
	end
	if type(mod) == "function" then
		local ok, res = pcall(mod, npcSurvivor, x, y, z)
		if ok then
			return res ~= false
		end
		print("movement direct-call error:", tostring(res))
	end
	return false
end

local GOAP_Hunt_Player = {}
GOAP_Hunt_Player.name = "GOAP_Hunt_Player"

setmetatable(GOAP_Hunt_Player, { __index = (require("05_npc_actions/PZNS_GOAP_Actions") or {}) })

function GOAP_Hunt_Player:isValid(npcSurvivor, targetID)
	-- valid if NPC and target are valid
	if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
		return false
	end
end

function GOAP_Hunt_Player:cost()
	return 5.0
end

-- PLANNING: pure preconditions/effects (do NOT call buildWorldState here)
function GOAP_Hunt_Player:getPreconditions()
	-- only allow this action to be considered when planner snapshot has player visible
	return { isTargetVisible = true }
end

function GOAP_Hunt_Player:getEffects()
	-- planner-level effect:a movement target will be a vailable (planner can reason about movement)
	return {
		isRunToLocationAvailable = true,
		isWalkToLocationAvailable = true,
		hasReachedRunToLocation = true,
		hasReachedWalkToLocation = true,
	}
end

-- RUNTIME: perform does live queries and enqueues pathfinding (safe to call buildWorldState / getSpecificPlayer here)
-- return true when finished, false while moving
function GOAP_Hunt_Player.perform(npcSurvivor)
	local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor)

	print("Target visible:", ws.isTargetVisible)
	print("Target in follow range:", ws.isTargetInFollowRange)
	print("Distance from target:", ws.distanceFromTarget)

	print(ws.targetX, ws.targetY, ws.targetZ)

	npcSurvivor.currentAction = "Walking"
	PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor)
	PZNS_WalkToo.PZNS_WalkToSquareXYZ(npcSurvivor, ws.targetX, ws.targetY, ws.targetZ)

	-- -- try to start running first, then walking
	-- local started = false
	-- if okRun and ws.isRunToLocationAvailable then
	-- 	started = tryCallMovement(PZNS_RunTo, { "RunToSquareXYZ", "RunTo", "execute", "run" }, npcSurvivor, tx, ty, tz)
	-- end
	-- if not started and okWalk and ws.isWalkToLocationAvailable then
	-- 	started =
	-- 		tryCallMovement(PZNS_WalkTo, { "WalkToSquareXYZ", "WalkTo", "execute", "walk" }, npcSurvivor, tx, ty, tz)
	-- end
	--
	-- if started then
	-- 	print("Movement started")
	-- 	return false -- still moving
	-- end
	--
	-- print("Movement unavailable or failed; finishing action")
	-- return true
end

return GOAP_Hunt_Player
