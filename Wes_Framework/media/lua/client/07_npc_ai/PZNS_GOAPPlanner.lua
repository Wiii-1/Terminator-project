local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")

local actions = {
	require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponAiming"),
	require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponRangedAttack"),
	require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponReload"),
}

local goals = {
	-- require each goal module you have here
	require("07_npc_ai/GOAP_GOALS/GetWeapon_Goal"),
	require("07_npc_ai/GOAP_GOALS/killPlayer_Goal"),
	-- add more goal modules as you create them
}

local PZNS_GOAPPlanner = {}
local M = {}

---@param worldState ws
---@return table goal
---
function M.selectBest(ws)
	local selectBestGoal = nil
	local highestPriority = -math.huge
	for _, goal in ipairs(goals) do
		if goal.isValid(ws) then
			local priority = goal.priority()
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

function PZNS_GOAPPlanner.plan(worldState, goal)
	print("[GOAP PLAN] ========== PLAN STARTED ==========")
	print("[GOAP PLAN] Timestamp: " .. os.time())

	local available = actions

	-- ========== VALIDATION ==========
	print("[GOAP PLAN] Validating inputs...")
	if not worldState or not goal then
		print("[GOAP PLAN] ERROR: Invalid inputs!")
		print("[GOAP PLAN]   worldState: " .. tostring(worldState))
		print("[GOAP PLAN]   goal: " .. tostring(goal))
		return nil
	end

	-- ========== WORLD STATE DEBUG ==========
	print("[GOAP PLAN] Initial World State:")
	for k, v in pairs(worldState) do
		print("[GOAP PLAN]   " .. k .. " = " .. tostring(v))
	end

	-- ========== GOAL STATE DEBUG ==========
	print("[GOAP PLAN] Goal State (Desired):")
	for k, v in pairs(goal) do
		print("[GOAP PLAN]   " .. k .. " = " .. tostring(v))
	end

	-- ========== AVAILABLE ACTIONS DEBUG ==========
	print("[GOAP PLAN] Available Actions (" .. #available .. " total):")
	for i, act in ipairs(available) do
		print("[GOAP PLAN]   [" .. i .. "] " .. (act.name or "Unknown"))
		print("[GOAP PLAN]       Cost: " .. (act.get_Cost() or 1))
		if act.get_preconditions() then
			local preStr = "{"
			for k, v in pairs(act.get_preconditions()) do
				preStr = preStr .. k .. "=" .. tostring(v) .. ", "
			end
			preStr = preStr .. "}"
			print("[GOAP PLAN]       Preconditions: " .. preStr)
		end
		if act.get_effects() then
			local effStr = "{"
			for k, v in pairs(act.get_effects()) do
				effStr = effStr .. k .. "=" .. tostring(v) .. ", "
			end
			effStr = effStr .. "}"
			print("[GOAP PLAN]       Effects: " .. effStr)
		end
	end

	-- ========== INITIALIZE A* SEARCH ==========
	local open = {}
	local closed = {}

	print("[GOAP PLAN] Initializing open list...")
	local initialHeuristic = local_heuristic(worldState, goal)
	table.insert(open, {
		state = local_copyState(worldState),
		g = 0,
		h = initialHeuristic,
		plan = {},
	})
	print("[GOAP PLAN] Initial h-value (mismatches): " .. initialHeuristic)
	print("[GOAP PLAN] Open list size: " .. #open)

	-- ========== A* MAIN LOOP ==========
	print("[GOAP PLAN] ===== A* SEARCH STARTED =====")

	local iteration = 0
	local maxIterations = 1000

	while #open > 0 do
		iteration = iteration + 1

		if iteration > maxIterations then
			print("[GOAP PLAN] ERROR: Max iterations (" .. maxIterations .. ") exceeded!")
			print("[GOAP PLAN] Possible infinite loop or very complex planning problem")
			return nil
		end

		-- ========== SORT OPEN LIST ==========
		print("\n[GOAP PLAN] --- Iteration " .. iteration .. " ---")
		print("[GOAP PLAN] Sorting open list (" .. #open .. " nodes)...")

		table.sort(open, function(a, b)
			return (a.g + a.h) < (b.g + b.h)
		end)

		-- ========== DISPLAY SORTED OPEN LIST (TOP 5) ==========
		print("[GOAP PLAN] Top 5 nodes by f-score:")
		for i = 1, math.min(5, #open) do
			local n = open[i]
			print(
				"[GOAP PLAN]   ["
					.. i
					.. "] f="
					.. (n.g + n.h)
					.. " (g="
					.. n.g
					.. ", h="
					.. n.h
					.. ") actions="
					.. #n.plan
			)
		end

		-- ========== POP BEST NODE ==========
		local node = table.remove(open, 1)
		print("[GOAP PLAN] Popped best node: f=" .. (node.g + node.h) .. ", actions=" .. #node.plan)

		-- ========== CHECK IF GOAL REACHED ==========
		local goalDistance = local_heuristic(node.state, goal)
		print("[GOAP PLAN] Checking goal distance: " .. goalDistance)

		if goalDistance == 0 then
			print("[GOAP PLAN] ✓✓✓ GOAL REACHED! ✓✓✓")
			print("[GOAP PLAN] Plan found with " .. #node.plan .. " actions")
			print("[GOAP PLAN] Final plan:")
			for i, act in ipairs(node.plan) do
				print(
					"[GOAP PLAN]   ["
						.. i
						.. "] "
						.. (act.name or "Unknown")
						.. " (cost="
						.. (act.get_Cost() or 1)
						.. ")"
				)
			end
			print("[GOAP PLAN] Total cost: " .. node.g)
			print("[GOAP PLAN] ========== PLAN COMPLETE ==========")
			return node.plan
		end

		-- ========== ADD TO CLOSED SET ==========
		local nodeHash = local_stateHash(node.state)
		if not closed[nodeHash] then
			closed[nodeHash] = true
			print("[GOAP PLAN] Added to closed set. Closed size: " .. PZNS_GOAPPlanner._countTable(closed))

			-- ========== TRY ALL ACTIONS ==========
			print("[GOAP PLAN] Trying actions from current node...")
			local actionsTried = 0
			local actionsValid = 0

			for actionIdx, act in ipairs(available) do
				actionsTried = actionsTried + 1

				if act then
					-- ========== CHECK PRECONDITIONS ==========
					if local_meetsPreconditions(node.state, act.get_preconditions()) then
						actionsValid = actionsValid + 1
						print(
							"[GOAP PLAN]   ✓ Action "
								.. actionIdx
								.. " ("
								.. (act.name or "Unknown")
								.. ") preconditions MET"
						)

						-- ========== APPLY EFFECTS ==========
						local newState = local_applyEffects(node.state, act.get_effects())

						-- ========== BUILD NEW PLAN ==========
						local newPlan = {}
						for i = 1, #node.plan do
							newPlan[i] = node.plan[i]
						end
						table.insert(newPlan, act)

						-- ========== CALCULATE COSTS ==========
						local g2 = node.g + (act.get_Cost() or 1)
						local h2 = local_heuristic(newState, goal)
						local f2 = g2 + h2

						print("[GOAP PLAN]     Cost: g=" .. g2 .. ", h=" .. h2 .. ", f=" .. f2)
						print("[GOAP PLAN]     New plan length: " .. #newPlan)

						-- ========== CHECK IF VISITED ==========
						local nhash = local_stateHash(newState)
						if not closed[nhash] then
							table.insert(open, {
								state = newState,
								g = g2,
								h = h2,
								plan = newPlan,
							})
							print("[GOAP PLAN]     ✓ Added to open list")
						else
							print("[GOAP PLAN]     ✗ State already visited (closed)")
						end
					else
						print(
							"[GOAP PLAN]   ✗ Action "
								.. actionIdx
								.. " ("
								.. (act.name or "Unknown")
								.. ") preconditions NOT MET"
						)

						-- ========== DEBUG PRECONDITION FAILURE ==========
						if act.get_preconditions() then
							for k, v in pairs(act.get_preconditions()) do
								local stateVal = node.state[k]
								if stateVal ~= v then
									print(
										"[GOAP PLAN]       Missing: "
											.. k
											.. " (need="
											.. tostring(v)
											.. ", have="
											.. tostring(stateVal)
											.. ")"
									)
								end
							end
						end
					end
				else
					print("[GOAP PLAN]   ✗ Action " .. actionIdx .. " is nil!")
				end
			end

			print("[GOAP PLAN] Actions processed: " .. actionsTried .. " tried, " .. actionsValid .. " valid")
			print("[GOAP PLAN] Open list now has " .. #open .. " nodes")
		else
			print("[GOAP PLAN] Node already in closed set, skipping (duplicate)")
		end

		print("[GOAP PLAN] Open list remaining: " .. #open)
	end

	-- ========== NO PLAN FOUND ==========
	print("[GOAP PLAN] ✗✗✗ NO PLAN FOUND ✗✗✗")
	print("[GOAP PLAN] Open list exhausted after " .. iteration .. " iterations")
	print("[GOAP PLAN] Closed set size: " .. PZNS_GOAPPlanner._countTable(closed))
	print("[GOAP PLAN] ========== PLAN FAILED ==========")
	return nil
end

-- ========== HELPER: Count table entries ==========
function PZNS_GOAPPlanner._countTable(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- -- plan(worldState, goal, actionList?)
-- -- returns ordered array of action modules or nil if no plan
-- function PZNS_GOAPPlanner.plan(worldState, goal)
-- 	local available = actions
-- 	if not worldState or not goal then
-- 		return nil
-- 	end
--
-- 	local open = {}
-- 	local closed = {}
--
-- 	table.insert(open, { state = local_copyState(worldState), g = 0, h = local_heuristic(worldState, goal), plan = {} })
--
-- 	while #open > 0 do
-- 		table.sort(open, function(a, b)
-- 			return (a.g + a.h) < (b.g + b.h)
-- 		end)
-- 		local node = table.remove(open, 1)
--
-- 		if local_heuristic(node.state, goal) == 0 then
-- 			return node.plan
-- 		end
--
-- 		local nodeHash = local_stateHash(node.state)
-- 		if not closed[nodeHash] then
-- 			closed[nodeHash] = true
--
-- 			for _, act in ipairs(available) do
-- 				if act and local_meetsPreconditions(node.state, act.get_preconditions()) then
-- 					local newState = local_applyEffects(node.state, act.get_effects()())
-- 					local newPlan = {}
-- 					for i = 1, #node.plan do
-- 						newPlan[i] = node.plan[i]
-- 					end
-- 					table.insert(newPlan, act)
-- 					local g2 = node.g + (act.get_Cost()  or 1)
-- 					local nhash = local_stateHash(newState)
-- 					if not closed[nhash] then
-- 						table.insert(
-- 							open,
-- 							{ state = newState, g = g2, h = local_heuristic(newState, goal), plan = newPlan }
-- 						)
-- 					end
-- 				end
-- 			end
-- 		end
-- 		return nil
-- 	end
-- end
--
-- convenience: build world state snapshot for npc and plan
-- also get the best goal
function PZNS_GOAPPlanner.planForNPC(ws)
	if not ws then
		print("PZNS_GOAPPlanner: failed to build world state")
		return nil
	end

	local desired = nil
	local selected = M.selectBest(ws)
	desired = selected.getDesiredState()

	-- debug: list desired keys
	for k, v in pairs(desired) do
		print("PZNS_GOAPPlanner: desired ->", k, v)
	end

	return PZNS_GOAPPlanner.plan(ws, desired)
end
return PZNS_GOAPPlanner
