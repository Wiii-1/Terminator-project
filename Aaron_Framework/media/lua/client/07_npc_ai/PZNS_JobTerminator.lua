local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local PZNS_GOAPPlanner = require("07_npc_ai/PZNS_GOAPPlanner")

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
