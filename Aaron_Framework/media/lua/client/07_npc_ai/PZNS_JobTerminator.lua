local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local PZNS_GOAPPlanner = require("07_npc_ai/PZNS_GOAPPlanner")
local PZNS_GOAPGoals = require("07_npc_ai/PZNS_GOAPGoals")

<<<<<<< HEAD
-- Terminator target Player
local function getTargetIsoPlayerByID(targetID)
	local targetIsoPlayer
	--
	if targetID == "Player0" then
		targetIsoPlayer = getSpecificPlayer(0)
	else
		local targetNPC = PZNS_NPCsManager.getActiveNPCBySurvivorID(targetID)
		if targetNPC then
			targetIsoPlayer = targetNPC.npcIsoPlayerObject
		end
	end
	return targetIsoPlayer
end

-- Terminator within follow range of the player
local function isTerminatorInFollowRange(npcIsoPlayer, targetIsoPlayer)
	local distanceFromTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(npcIsoPlayer, targetIsoPlayer)
	if distanceFromTarget > CompanionFollowRange then
		return false
	end
	return true
end

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
	-- NPC validations
	if PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) == false then
		return
	end
	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
	if targetID ~= "" and targetID ~= npcSurvivor.followTargetID then
		npcSurvivor.followTargetID = targetID
	end

	if not targetID or targetID == "" then
		print(string.format("Invalid targetID (%s) for Terminator job", targetID))
		-- optional existing calls left intact
		PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, "Wander In Cell")
		return
	end
	-- Player validations
	local targetIsoPlayer = getTargetIsoPlayerByID(targetID)
	if targetIsoPlayer == nil then
		return
	end

	-- Build GOAP worldstate and request plan (auto-select best goal)
	local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor, { heavyScan = true })
	if not ws then
		print("PZNS_JobTerminator: failed to build world state")
		return
	end

	local plan = PZNS_GOAPPlanner.planForNPC(npcSurvivor, nil, nil)
	if not plan then
		-- no plan found; you can fallback to other behaviors here
		-- e.g., follow player if in range, wander otherwise
		if isTerminatorInFollowRange(npcIsoPlayer, targetIsoPlayer) then
			-- continue following (existing follow job/logic)
			-- PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, "Follow")
		end
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
=======
-- ============================================================================
-- CONFIGURATION - TUNE THESE FOR PERFORMANCE/BEHAVIOR
-- ============================================================================

local CONFIG = {
	PLAN_COOLDOWN_TICKS = 120, -- Plan every 2 seconds (lower = more responsive, higher = faster)
	MAX_EXPANSIONS = 50, -- Stop A* search after N expansions (prevents runaway)
	SIGHT_RANGE = 400, -- ~20 tiles squared
	CLOSE_RANGE = 4, -- Within striking distance
	AIM_RANGE_MULTIPLIER = 1.0, -- Weapon range check multiplier
	VERBOSE = false, -- Enable debug logging
}

-- ============================================================================
-- HEURISTIC WEIGHTS - Prioritize goals intelligently
-- ============================================================================
-- Higher weight = more important to A* search
-- This guides the planner toward realistic goals faster

local HEURISTIC_WEIGHTS = {
	playerEliminated = 10, -- Primary goal: kill player
	atPlayer = 5, -- Essential precondition
	aimed = 2, -- Good to have before attacking
	hasWeapon = 3, -- Critical precondition
	weaponLoaded = 2, -- Important for ranged combat
	safe = 1, -- Low priority fallback
}

-- ============================================================================
-- GLOBAL STATE - Per-NPC caching
-- ============================================================================

local planCache = {} -- Cache plans by state hash
local globalPlanCooldown = {} -- Per-NPC cooldown tracking

-- ============================================================================
-- UTILITY: State Hashing (for caching and debugging)
-- ============================================================================

local function stateToHash(state)
	local keys = {}
	for k in pairs(state) do
		table.insert(keys, tostring(k))
	end
	table.sort(keys)

	local parts = {}
	for _, k in ipairs(keys) do
		local v = state[k]
		parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
	end

	return table.concat(parts, ";")
end

-- ============================================================================
-- UTILITY: Weighted Heuristic (guides A* search)
-- ============================================================================

local function calculateHeuristic(state, goal)
	local h = 0

	for goalKey, goalValue in pairs(goal) do
		if state[goalKey] ~= goalValue then
			-- Weight this mismatch by importance
			local weight = HEURISTIC_WEIGHTS[goalKey] or 1
			h = h + weight
		end
	end

	return h
end

-- ============================================================================
-- A* PLANNING ENGINE (Optimized)
-- ============================================================================

local function planTerminatorActions(startState, availableActions, goal)
	if CONFIG.VERBOSE then
		print("[Terminator] Planning started, maxExpansions=" .. CONFIG.MAX_EXPANSIONS)
	end

	-- Priority queue: nodes sorted by f = g + h (cost + heuristic)
	local openSet = {
		{
			state = startState,
			plan = {},
			g = 0, -- Cost to reach this state
			h = calculateHeuristic(startState, goal), -- Estimated cost to goal
		},
	}

	local closedSet = {} -- States we've already explored
	local expansions = 0

	while #openSet > 0 do
		-- Sort by f-score and take best node
		table.sort(openSet, function(a, b)
			return (a.g + a.h) < (b.g + b.h)
		end)

		local currentNode = table.remove(openSet, 1)
		expansions = expansions + 1

		-- OPTIMIZATION: Stop if exceeded max expansions
		if expansions >= CONFIG.MAX_EXPANSIONS then
			if CONFIG.VERBOSE then
				print("[Terminator] Max expansions reached (" .. expansions .. ")")
			end
			return nil -- Failed to find plan
		end

		-- Check if goal is satisfied
		local goalSatisfied = true
		for key, value in pairs(goal) do
			if currentNode.state[key] ~= value then
				goalSatisfied = false
				break
			end
		end

		if goalSatisfied then
			if CONFIG.VERBOSE then
				print(
					"[Terminator] Plan found! Length="
						.. #currentNode.plan
						.. ", Cost="
						.. currentNode.g
						.. ", Expansions="
						.. expansions
				)
			end
			return currentNode.plan
		end

		-- Mark this state as explored
		local stateHash = stateToHash(currentNode.state)
		if closedSet[stateHash] and closedSet[stateHash] <= currentNode.g then
			-- Skip: already found better or equal path to this state
			goto continue
		end
		closedSet[stateHash] = currentNode.g

		-- Expand: try all applicable actions
		for _, action in ipairs(availableActions) do
			-- Check preconditions
			local canApply = true
			for precondKey, precondValue in pairs(action.preconditions or {}) do
				if currentNode.state[precondKey] ~= precondValue then
					canApply = false
					break
				end
			end

			if canApply then
				-- Apply effects to create new state
				local newState = {}
				for k, v in pairs(currentNode.state) do
					newState[k] = v
				end

				for effectKey, effectValue in pairs(action.effects or {}) do
					newState[effectKey] = effectValue
				end

				-- Calculate cost to reach new state
				local newG = currentNode.g + (action.cost or 1)
				local newHash = stateToHash(newState)

				-- Skip if we found a better path to this state already
				if closedSet[newHash] and closedSet[newHash] <= newG then
					goto next_action
				end

				-- Create new plan (copy + append action)
				local newPlan = {}
				for i, step in ipairs(currentNode.plan) do
					newPlan[i] = step
				end
				table.insert(newPlan, action)

				-- Add to open set for exploration
				table.insert(openSet, {
					state = newState,
					plan = newPlan,
					g = newG,
					h = calculateHeuristic(newState, goal),
				})
			end

			::next_action::
		end

		::continue::
	end

	if CONFIG.VERBOSE then
		print("[Terminator] No plan found after " .. expansions .. " expansions")
	end
	return nil
end

-- ============================================================================
-- WORLD SENSING (What the Terminator perceives)
-- ============================================================================

local function senseWorld(npcSurvivor)
	local worldState = {
		playerSeen = false,
		atPlayer = false,
		hasWeapon = false,
		weaponLoaded = false,
		inAimRange = false,
		playerPosition = nil,
	}

	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
	if not npcIsoPlayer then
		return worldState
	end

	local player = getPlayer()
	if not player then
		return worldState
	end

	local playerX, playerY = player:getX(), player:getY()
	local npcX, npcY = npcIsoPlayer:getX(), npcIsoPlayer:getY()
	local dx, dy = playerX - npcX, playerY - npcY
	local distSquared = dx * dx + dy * dy

	-- Can we see the player?
	if distSquared <= CONFIG.SIGHT_RANGE then
		worldState.playerSeen = true
		worldState.playerPosition = {
			x = playerX,
			y = playerY,
			z = player:getZ(),
		}
	end

	-- Are we close to the player?
	if distSquared <= CONFIG.CLOSE_RANGE then
		worldState.atPlayer = true
	end

	-- Do we have a weapon?
	local weapon = npcIsoPlayer:getPrimaryHandItem()
	worldState.hasWeapon = (weapon ~= nil and weapon:IsWeapon())

	-- Is weapon loaded?
	if weapon and weapon:IsWeapon() then
		worldState.weaponLoaded = (weapon:getAmmoCount() and weapon:getAmmoCount() > 0)

		-- Check if player is in range
		local range = weapon:getMaxRange() or 2
		worldState.inAimRange = (distSquared <= (range * range * CONFIG.AIM_RANGE_MULTIPLIER))
	else
		worldState.weaponLoaded = false
		worldState.inAimRange = false
	end

	return worldState
end

-- ============================================================================
-- ACTION FILTERING (Only consider relevant actions)
-- ============================================================================
-- This dramatically reduces search space by excluding impossible/irrelevant actions

local function filterRelevantActions(worldState, allActions)
	local relevant = {}

	-- Priority 1: If no weapon, ONLY consider getting one
	if not worldState.hasWeapon then
		for _, action in ipairs(allActions) do
			if action.name == "GatherWeapon" then
				table.insert(relevant, action)
				break
			end
		end
		return relevant -- Return early with just 1 action
	end

	-- Priority 2: If weapon empty, ONLY consider reload
	if not worldState.weaponLoaded then
		for _, action in ipairs(allActions) do
			if action.name == "ReloadWeapon" then
				table.insert(relevant, action)
				break
			end
		end
		return relevant -- Return early with just 1 action
	end

	-- Priority 3: If in aim range, consider combat
	if worldState.inAimRange and worldState.playerSeen then
		for _, action in ipairs(allActions) do
			if action.name == "AimWeapon" or action.name == "AttackWeapon" then
				table.insert(relevant, action)
			end
		end
		if #relevant > 0 then
			return relevant
		end
	end

	-- Priority 4: If can see player but not in range, consider moving
	if worldState.playerSeen and not worldState.atPlayer then
		for _, action in ipairs(allActions) do
			if action.name == "MoveToPlayer" or action.name == "HuntPlayer" then
				table.insert(relevant, action)
			end
		end
		if #relevant > 0 then
			return relevant
		end
	end

	-- Priority 5: If can reach player, consider melee
	if worldState.atPlayer then
		for _, action in ipairs(allActions) do
			if action.name == "AttackPlayer" or action.name == "UseMelee" then
				table.insert(relevant, action)
			end
		end
		if #relevant > 0 then
			return relevant
		end
	end

	-- Fallback: return all actions
	return allActions
end

-- ============================================================================
-- MAIN JOB FUNCTION (Called every game tick)
-- ============================================================================

local function PZNS_JobTerminator(npcSurvivor)
	if not npcSurvivor or not npcSurvivor.isTerminator then
		return
	end

	-- Safety checks
	if not npcSurvivor.npcIsoPlayerObject then
		return
	end

	if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_GetIsNPCSquareLoaded then
		if not PZNS_UtilsNPCs.PZNS_GetIsNPCSquareLoaded(npcSurvivor) then
			return
		end
	end

	-- Keep alive (optional)
	if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_EnsureNPCAlive then
		PZNS_UtilsNPCs.PZNS_EnsureNPCAlive(npcSurvivor)
	end

	-- Initialize cooldown tracking
	if not globalPlanCooldown[npcSurvivor.survivorID] then
		globalPlanCooldown[npcSurvivor.survivorID] = 0
	end

	-- Decrement per-NPC cooldown
	if globalPlanCooldown[npcSurvivor.survivorID] > 0 then
		globalPlanCooldown[npcSurvivor.survivorID] = globalPlanCooldown[npcSurvivor.survivorID] - 1
	end

	-- ========================================================================
	-- SENSE WORLD
	-- ========================================================================

	local worldState = senseWorld(npcSurvivor)
	local goal = { playerEliminated = true }

	-- ========================================================================
	-- SKIP PLANNING IF NO THREAT
	-- ========================================================================

	if not worldState.playerSeen and (not npcSurvivor.goapPlan or #npcSurvivor.goapPlan == 0) then
		return -- No player visible and no active plan, save CPU
	end

	-- ========================================================================
	-- GENERATE OR RETRIEVE PLAN
	-- ========================================================================

	if not npcSurvivor.goapPlan or #npcSurvivor.goapPlan == 0 then
		-- Need a plan

		if globalPlanCooldown[npcSurvivor.survivorID] <= 0 then
			-- Cooldown expired, allowed to plan

			local stateHash = stateToHash(worldState)

			-- OPTIMIZATION 1: Check cache first
			if planCache[stateHash] then
				if CONFIG.VERBOSE then
					print("[Terminator] Using cached plan for state: " .. stateHash)
				end
				npcSurvivor.goapPlan = planCache[stateHash]
				globalPlanCooldown[npcSurvivor.survivorID] = CONFIG.PLAN_COOLDOWN_TICKS
			else
				-- Not in cache, need to plan

				-- OPTIMIZATION 2: Filter relevant actions to reduce search space
				local relevantActions = filterRelevantActions(worldState, TerminatorActions.getAll())

				-- OPTIMIZATION 3: Run A* planning with expansions limit
				local newPlan = planTerminatorActions(worldState, relevantActions, goal)

				if newPlan then
					-- Cache the plan
					planCache[stateHash] = newPlan
					npcSurvivor.goapPlan = newPlan
					globalPlanCooldown[npcSurvivor.survivorID] = CONFIG.PLAN_COOLDOWN_TICKS

					if CONFIG.VERBOSE then
						print("[Terminator] New plan generated (" .. #newPlan .. " actions), cached")
					end
				else
					-- Planning failed, wait before retrying
					npcSurvivor.goapPlan = {}
					globalPlanCooldown[npcSurvivor.survivorID] = math.max(2, math.floor(CONFIG.PLAN_COOLDOWN_TICKS / 4))

					if CONFIG.VERBOSE then
						print("[Terminator] Planning failed, will retry soon")
					end
				end
			end
		end
	end

	-- ========================================================================
	-- EXECUTE CURRENT PLAN
	-- ========================================================================

	if npcSurvivor.goapPlan and #npcSurvivor.goapPlan > 0 then
		local currentAction = npcSurvivor.goapPlan[1]

		local success = false
		local ok, err = pcall(function()
			success = currentAction.perform(currentAction, npcSurvivor, worldState)
		end)

		if not ok then
			-- Action execution failed
			if CONFIG.VERBOSE then
				print("[Terminator] Action '" .. currentAction.name .. "' failed: " .. tostring(err))
			end
			npcSurvivor.goapPlan = {}
			return
		end

		if success then
			-- Action complete, remove from plan
			table.remove(npcSurvivor.goapPlan, 1)

			if CONFIG.VERBOSE then
				print("[Terminator] Action '" .. currentAction.name .. "' completed")
			end
		else
			-- Action still in progress, let it continue next tick
			if CONFIG.VERBOSE then
				print("[Terminator] Action '" .. currentAction.name .. "' in progress...")
			end
		end
	end
end

-- ============================================================================
-- EXPORTED API
-- ============================================================================

return {
	tick = PZNS_JobTerminator,
	senseWorld = senseWorld,
	plan = planTerminatorActions,
	heuristic = calculateHeuristic,
	stateHash = stateToHash,
	config = CONFIG,
}
>>>>>>> fd00689 (resolve merge conflict)
