local PZNS_GOAPPlanner = require("07_npc_ai/PZNS_GOAPPlanner")
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")

local PZNS_GOAP_Hunt_Player = require("05_npc_actions/GOAP_Actions/PZNS_GOAP_Hunt_Player")
local PZNS_GOAP_Walk_to = require("05_npc_actions/GOAP_Actions/PZNS_GOAP_Walk_to")
local PZNS_GOAP_WeaponAiming = require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponAiming")
local PZNS_GOAP_WeaponRangedAttack = require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponRangedAttack")

<<<<<<< HEAD
local PZNS_JobTerminator = {}
=======
local function tick()
	return { plan = true }
end

TICK = tick()
>>>>>>> c7a116e (final struggle)

local PLAN_COOLDOWN = 0.5      -- seconds between replans when no stored plan
local JOBTERMINATOR_COOLDOWN = 0.15 -- seconds between JobTerminator runs per NPC
local now = os and os.clock or function() return 0 end

--- Execute a single action module.
--- Returns: success(boolean), isRunning(boolean)
local function executeAction(npc, act, ws)
    if not act then
        return false, false
    end

<<<<<<< HEAD
    -- prefer method-style perform (act:perform)
    local runFn = act.perform
    if type(runFn) == "function" then
        -- call safely; actions should return false while in-progress, true/nil when finished
        local ok, res = pcall(runFn, act, npc, ws)
        if not ok then
            print("PZNS_JobTerminator: action error:", tostring(res))
            return false, false
        end
        -- res == false -> running; res == true or nil -> finished successfully
        if res == false then
            return true, true
        end
        return true, false
    end

    -- fallback: apply effects directly to worldstate (instant)
    local effsFn = act.get_effects
    if type(effsFn) == "function" then
        local effects = effsFn(act)
        if type(effects) == "table" then
            for k, v in pairs(effects) do
                ws[k] = v
            end
            return true, false
        end
    end
=======
	-- prefer asynchronous or coroutine-style action functions if present
	local runFn = act.perform(npc)
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

	TICK.plan = true
	-- fallback: apply effects directly to worldstate (instant)
	if type(act.get_effects()) == "table" then
		for k, v in pairs(act.get_effects()) do
			ws[k] = v
		end
		return true
	end
>>>>>>> c7a116e (final struggle)

    return false, false
end

--- Terminator: manage one NPC plan & execute a single action per invocation.
--- @param npcSurvivor table
--- @param targetID string|nil
function PZNS_JobTerminator(npcSurvivor, targetID)
<<<<<<< HEAD
    if not npcSurvivor then return end

    -- per-NPC throttle to avoid tight loops
    local cur = now()
    local lastRun = npcSurvivor._PZNS_jobLastTime or 0
    if (cur - lastRun) < JOBTERMINATOR_COOLDOWN then
        return
    end
    npcSurvivor._PZNS_jobLastTime = cur

    -- build (cached) worldstate for this npc (pass targetID through if desired)
    local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor, targetID)
=======
	if TICK.plan == true then
		local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor)
		local plan = PZNS_GOAPPlanner.planForNPC(ws)
		if not plan then
			print("no Plan ")
			return true
		else
			print("Plan done")
			TICK.plan = false
		end

		for i, act in ipairs(plan) do
			local success = executeAction(npcSurvivor, act, ws)
			if not success then
				print("PZNS_JobTerminator: action failed - will replan next tick")
				return -- stop and let next tick replan
			end
			-- update worldstate after successful action (many actions already modify world state)
			if type(act.get_effects()) == "table" then
				for k, v in pairs(act.get_effects()) do
					ws[k] = v
				end
			end
		end
	end

	-- local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor)
	--
	-- if TICK == 0 then
	-- 	-- use executeAction so action receives itself as 'self'
	-- 	PZNS_GOAP_Hunt_Player.perform(npcSurvivor)
	-- 	print("done")
	-- 	TICK = TICK + 1
	-- end
	--

	-- if TICK <= 0 then
	-- 	PZNS_GOAP_Walk_to.perform(npcSurvivor)
	-- 	print("done")
	-- 	TICK = TICK + 1
	-- end
>>>>>>> c7a116e (final struggle)

    -- ensure per-npc plan state
    local plan = npcSurvivor._PZNS_currentPlan
    local index = npcSurvivor._PZNS_planIndex or 1
    local lastPlanTime = npcSurvivor._PZNS_planLastTime or 0

    -- if no stored plan or finished, attempt to plan (throttled)
    if not plan or #plan == 0 or index > #plan then
        -- throttle replanning
        if (cur - lastPlanTime) < PLAN_COOLDOWN then
            return
        end

<<<<<<< HEAD
        local newPlan = PZNS_GOAPPlanner.planForNPC(ws)
        npcSurvivor._PZNS_planLastTime = cur
        if not newPlan or #newPlan == 0 then
            -- nothing to do
            npcSurvivor._PZNS_currentPlan = nil
            npcSurvivor._PZNS_planIndex = 1
            return
        end

        -- store plan and reset index
        npcSurvivor._PZNS_currentPlan = newPlan
        npcSurvivor._PZNS_planIndex = 1
        plan = newPlan
        index = 1
    end

    -- execute only the current action step (one action per run)
    local act = plan[index]
    if not act then
        -- nothing to do; clear plan
        npcSurvivor._PZNS_currentPlan = nil
        npcSurvivor._PZNS_planIndex = 1
        return
    end

    local ok, isRunning = executeAction(npcSurvivor, act, ws)
    if not ok and not isRunning then
        -- action failed immediately; clear plan and replan later
        print("PZNS_JobTerminator: action failed, clearing plan")
        npcSurvivor._PZNS_currentPlan = nil
        npcSurvivor._PZNS_planIndex = 1
        npcSurvivor._PZNS_planLastTime = cur
        return
    end

    if isRunning then
        -- action still in progress; do not advance plan or replan
        return
    end

    -- action finished -> advance index
    npcSurvivor._PZNS_planIndex = index + 1

    -- if finished last action, clear stored plan to allow replanning next invocation
    if npcSurvivor._PZNS_planIndex > #plan then
        npcSurvivor._PZNS_currentPlan = nil
        npcSurvivor._PZNS_planIndex = 1
        -- optionally reset lastPlanTime to allow immediate replanning next tick:
        npcSurvivor._PZNS_planLastTime = cur
    end

    -- apply declared effects from the action to ws (optional)
    local effsFn = act.get_effects
    if type(effsFn) == "function" then
        local effects = effsFn(act)
        if type(effects) == "table" then
            for k, v in pairs(effects) do
                ws[k] = v
            end
        end
    end
=======
	-- local plan = PZNS_GOAPPlanner.planForNPC(ws)
	-- if not plan then
	-- 	print("No plan :(( ")
	-- 	return
	-- end
	-- execute plan steps in order (blocking/synchronous example)

	--
	-- plan completed -> NPC achieved goal; you may reset job or choose next behavior
>>>>>>> c7a116e (final struggle)
end

return PZNS_JobTerminator;