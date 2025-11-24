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
	local available = actionList or actions

	if not worldState or not goal then
		print("[GOAP PLAN] ERROR: worldState or goal is nil")
		return nil
	end

	-- ========== DEBUG: PLAN START ==========
	print("\n[GOAP PLAN] ===== STARTING A* SEARCH =====")
	print("[GOAP PLAN] Available actions: " .. #available)
	print("[GOAP PLAN] Goal state:")
	for k, v in pairs(goal) do
		print("[GOAP PLAN]   " .. k .. " = " .. tostring(v))
	end
	print("[GOAP PLAN] Initial world state:")
	for k, v in pairs(worldState) do
		print("[GOAP PLAN]   " .. k .. " = " .. tostring(v))
	end

	local initialH = local_heuristic(worldState, goal)
	print("[GOAP PLAN] Initial heuristic (goal diffs): " .. initialH)
	print("[GOAP PLAN] =====================================\n")

	-- ========== ALGORITHM START ==========
	local open = {}
	local closed = {}
	local iterationCount = 0
	local maxIterations = 1000 -- Safety limit

	table.insert(open, {
		state = local_copyState(worldState),
		g = 0,
		h = local_heuristic(worldState, goal),
		plan = {},
	})

	while #open > 0 and iterationCount < maxIterations do
		iterationCount = iterationCount + 1

		-- ========== DEBUG: ITERATION START ==========
		print("[GOAP PLAN] --- Iteration " .. iterationCount .. " ---")
		print("[GOAP PLAN] Open list size: " .. #open)
		print("[GOAP PLAN] Closed set size: " .. #closed)

		-- Sort by f = g + h
		table.sort(open, function(a, b)
			return (a.g + a.h) < (b.g + b.h)
		end)

		-- ========== DEBUG: SHOW TOP NODES ==========
		print("[GOAP PLAN] Top 3 nodes in open list:")
		for i = 1, math.min(3, #open) do
			local n = open[i]
			print(
				"[GOAP PLAN]   ["
					.. i
					.. "] f="
					.. (n.g + n.h)
					.. " (g="
					.. n.g
					.. " + h="
					.. n.h
					.. "), plan_len="
					.. #n.plan
			)
		end

		-- Pick best
		local node = table.remove(open, 1)

		-- ========== DEBUG: POPPED NODE ==========
		print("[GOAP PLAN] Popped best node: f=" .. (node.g + node.h))
		print("[GOAP PLAN] Node state:")
		for k, v in pairs(node.state) do
			print("[GOAP PLAN]   " .. k .. " = " .. tostring(v))
		end
		print("[GOAP PLAN] Node plan length: " .. #node.plan)
		if #node.plan > 0 then
			print("[GOAP PLAN] Plan so far:")
			for i, action in ipairs(node.plan) do
				print("[GOAP PLAN]   [" .. i .. "] " .. (action.name or "unknown"))
			end
		end

		-- Check if goal reached
		local heuristicValue = local_heuristic(node.state, goal)
		print("[GOAP PLAN] Heuristic value: " .. heuristicValue)

		if heuristicValue == 0 then
			print("\n[GOAP PLAN] ===== SUCCESS! GOAL REACHED =====")
			print("[GOAP PLAN] Total iterations: " .. iterationCount)
			print("[GOAP PLAN] Final plan length: " .. #node.plan)
			print("[GOAP PLAN] Final plan:")
			for i, action in ipairs(node.plan) do
				print(
					"[GOAP PLAN]   ["
						.. i
						.. "] "
						.. (action.name or "unknown")
						.. " (cost="
						.. (action.cost or 1)
						.. ")"
				)
			end
			print("[GOAP PLAN] Total cost: " .. node.g)
			print("[GOAP PLAN] =========================================\n")
			return node.plan
		end

		-- Add to closed set
		local nodeHash = local_stateHash(node.state)

		if not closed[nodeHash] then
			closed[nodeHash] = true

			-- ========== DEBUG: GENERATING SUCCESSORS ==========
			print("[GOAP PLAN] Generating successors...")
			local successorCount = 0

			for _, act in ipairs(available) do
				if act then
					-- Check preconditions
					local preconditionsMet = local_meetsPreconditions(node.state, act.preconditions)

					if preconditionsMet then
						successorCount = successorCount + 1

						-- Apply effects
						local newState = local_applyEffects(node.state, act.effects)
						local newPlan = {}

						for i = 1, #node.plan do
							newPlan[i] = node.plan[i]
						end
						table.insert(newPlan, act)

						-- Calculate new cost
						local g2 = node.g + (act.cost or 1)
						local h2 = local_heuristic(newState, goal)

						-- ========== DEBUG: SUCCESSOR INFO ==========
						print("[GOAP PLAN]   Successor " .. successorCount .. ": " .. (act.name or "unknown"))
						print(
							"[GOAP PLAN]     Cost: "
								.. (act.cost or 1)
								.. ", New g: "
								.. g2
								.. ", New h: "
								.. h2
								.. ", f: "
								.. (g2 + h2)
						)

						if act.preconditions then
							print("[GOAP PLAN]     Preconditions:")
							for k, v in pairs(act.preconditions) do
								print("[GOAP PLAN]       " .. k .. " = " .. tostring(v))
							end
						end

						if act.effects then
							print("[GOAP PLAN]     Effects:")
							for k, v in pairs(act.effects) do
								print("[GOAP PLAN]       " .. k .. " = " .. tostring(v))
							end
						end

						-- Check if already visited
						local nhash = local_stateHash(newState)

						if not closed[nhash] then
							table.insert(open, {
								state = newState,
								g = g2,
								h = h2,
								plan = newPlan,
							})
							print("[GOAP PLAN]     Added to open list ✓")
						else
							print("[GOAP PLAN]     Already visited, skipped ✗")
						end
					else
						-- ========== DEBUG: PRECONDITIONS FAILED ==========
						print("[GOAP PLAN]   SKIPPED: " .. (act.name or "unknown") .. " - preconditions not met")
						if act.preconditions then
							for k, v in pairs(act.preconditions) do
								local hasIt = node.state[k]
								local matches = hasIt == v
								local status = matches and "✓" or "✗"
								print(
									"[GOAP PLAN]     "
										.. status
										.. " "
										.. k
										.. " (have: "
										.. tostring(hasIt)
										.. ", need: "
										.. tostring(v)
										.. ")"
								)
							end
						end
					end
				end
			end

			print("[GOAP PLAN] Successors generated: " .. successorCount)
		else
			print("[GOAP PLAN] Node already in closed set, skipping ✗")
		end

		print("[GOAP PLAN] --- End Iteration " .. iterationCount .. " ---\n")
	end

	-- ========== DEBUG: FAILURE ==========
	if iterationCount >= maxIterations then
		print("\n[GOAP PLAN] ===== FAILURE: MAX ITERATIONS REACHED =====")
	else
		print("\n[GOAP PLAN] ===== FAILURE: OPEN LIST EMPTY (NO PATH) =====")
	end
	print("[GOAP PLAN] Iterations: " .. iterationCount)
	print("[GOAP PLAN] Closed set size: " .. #closed)
	print("[GOAP PLAN] ================================================\n")

	return nil
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

	-- debug
	print("===== WORLDSTATE DEBUG =====")
	for key, value in pairs(ws) do
		print("  " .. key .. " = " .. tostring(value))
	end
	print("=============================")
	print("===== DESIRED DEBUG =====")
	for key, value in pairs(desired) do
		print("  " .. key .. " = " .. tostring(value))
	end
	print("=============================")

	-- debug: list desired keys
	for k, v in pairs(desired) do
		print("PZNS_GOAPPlanner: desired ->", k, v)
	end
	return PZNS_GOAPPlanner.plan(ws, desired, usedActions)
end
return PZNS_GOAPPlanner
