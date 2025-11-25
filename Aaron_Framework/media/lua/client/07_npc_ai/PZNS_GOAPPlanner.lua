local actions = {
	require("05_npc_actions/PZNS_GOAPGunMagazine"),
	require("05_npc_actions/PZNS_GOAPHuntPlayer"),
	require("05_npc_actions/PZNS_GOAPPickUpWeapon"),
	require("05_npc_actions/PZNS_GOAPRunTo"),
	require("05_npc_actions/PZNS_GOAPScavenge"),
	require("05_npc_actions/PZNS_GOAPSwitchWeapon"),
	require("05_npc_actions/PZNS_GOAPWalkTo"),
	require("05_npc_actions/PZNS_GOAPWeaponAiming"),
	require("05_npc_actions/PZNS_GOAPWeaponAttack"),
	require("05_npc_actions/PZNS_GOAPWeaponEquip"),
	require("05_npc_actions/PZNS_GOAPWeaponReload"),
}

local PZNS_Goal = require("07_npc_ai/PZNS_Goal")
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")

local PZNS_GOAPPlanner = {}

local goals = {
	-- require each goal module you have here
	require("07_npc_ai/GOAP_GOALS/GetWeapon_Goal"),
	require("07_npc_ai/GOAP_GOALS/killPlayer_Goal"),
	-- add more goal modules as you create them
}

local M = {}

function M.getGoals()
	return goals
end

function M.geValidGoals()
	local validGoals = {}
	for _, goal in ipairs(goals) do
		if goal.isValid() then
			table.insert(validGoals, goal)
		end
	end
	return validGoals
end

function M.selectBest(npc)
	local selectBestGoal = nil
	local highestPriority = -math.huge
	for _, goal in ipairs(goals) do
		if goal.isValid(npc) then
			local priority = goal.priority(npc)
			if priority > highestPriority then
				highestPriority = priority
				selectBestGoal = goal
			end
		end
	end
	return selectBestGoal
end

-- shallow copy of a state table
local local_copyState = function(s)
	local t = {}
	for k, v in pairs(s or {}) do
		t[k] = v
	end
	return t
end

-- check preconditions (all keys in pre must match state)
local local_meetsPreconditions = function(state, pre)
	if not pre then
		return true
	end
	for k, v in pairs(pre) do
		if state[k] ~= v then
			return false
		end
	end
	return true
end

-- apply effects to a copy of the state and return new state
local local_applyEffects = function(state, effects)
	local ns = local_copyState(state)
	for k, v in pairs(effects or {}) do
		ns[k] = v
	end
	return ns
end

-- deterministic text key for a state (used to detect revisits)
local local_stateHash = function(state)
	local keys = {}
	for k, _ in pairs(state or {}) do
		table.insert(keys, k)
	end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do
		parts[#parts + 1] = k .. ":" .. tostring(state[k])
	end
	return table.concat(parts, "|")
end

-- simple heuristic: number of mismatched goal predicates
local local_heuristic = function(state, goal)
	local n = 0
	for k, v in pairs(goal or {}) do
		if state[k] ~= v then
			n = n + 1
		end
	end
	return n
end

-- plan(worldState, goal, actionList?)
-- returns ordered array of action modules or nil if no plan
function PZNS_GOAPPlanner.plan(worldState, goal, actionList)
	local available = actions
	if not worldState or not goal then
		return nil
	end

	local open = {}
	local closed = {}

	table.insert(open, { state = local_copyState(worldState), g = 0, h = local_heuristic(worldState, goal), plan = {} })

	while #open > 0 do
		table.sort(open, function(a, b)
			return (a.g + a.h) < (b.g + b.h)
		end)
		local node = table.remove(open, 1)

		if local_heuristic(node.state, goal) == 0 then
			return node.plan
		end

		local nodeHash = local_stateHash(node.state)
		if not closed[nodeHash] then
			closed[nodeHash] = true

			for _, act in ipairs(available) do
				if act and local_meetsPreconditions(node.state, act.preconditions) then
					local newState = local_applyEffects(node.state, act.effects)
					local newPlan = {}
					for i = 1, #node.plan do
						newPlan[i] = node.plan[i]
					end
					table.insert(newPlan, act)
					local g2 = node.g + (act.cost or 1)
					local nhash = local_stateHash(newState)
					if not closed[nhash] then
						table.insert(
							open,
							{ state = newState, g = g2, h = local_heuristic(newState, goal), plan = newPlan }
						)
					end
				end
			end
		end
		return nil
	end
end

-- convenience: build world state snapshot for npc and plan
function PZNS_GOAPPlanner.planForNPC(npcSurvivor, goalOrDesired, actionList)
	local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor, { heavyScan = false })
	if not ws then
		print("PZNS_GOAPPlanner: failed to build world state")
		return nil
	end

	local desired = nil
	local usedActions = actionList or actions

	-- Resolve nil => auto-select best goal module
	if not goalOrDesired then
		local selected = M.selectBest(npcSurvivor)
		if not selected then
			print("PZNS_GOAPPlanner: no valid goal found for NPC")
			return nil
		end
		if type(selected.getDesiredState) ~= "function" then
			print("PZNS_GOAPPlanner: selected goal missing getDesiredState()")
			return nil
		end
		local ok, ds = pcall(selected.getDesiredState, npcSurvivor)
		if not ok or type(ds) ~= "table" then
			print("PZNS_GOAPPlanner: selected goal.getDesiredState() failed or returned non-table")
			return nil
		end
		desired = ds
	elseif type(goalOrDesired) == "table" and type(goalOrDesired.getDesiredState) == "function" then
		local ok, ds = pcall(goalOrDesired.getDesiredState, npcSurvivor)
		if not ok or type(ds) ~= "table" then
			print("PZNS_GOAPPlanner: provided goal module failed getDesiredState()")
			return nil
		end
		desired = ds
	else
		desired = goalOrDesired
	end

	-- debug: list desired keys
	for k, v in pairs(desired) do
		print("PZNS_GOAPPlanner: desired ->", k, v)
	end

	return PZNS_GOAPPlanner.plan(ws, desired, usedActions)
end
return PZNS_GOAPPlanner
