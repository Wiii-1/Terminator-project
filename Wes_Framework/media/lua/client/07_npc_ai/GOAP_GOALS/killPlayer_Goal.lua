-- ...existing code...
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local Goal = require("07_npc_ai/PZNS_Goal")

local KillPlayer_Goal = {}
KillPlayer_Goal.name = "KillPlayer_Goal"

setmetatable(KillPlayer_Goal, { __index = Goal })

function KillPlayer_Goal.isValid(npc)
	if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npc) then
		return false
	end
	local ws = PZNS_GOAPWorldState.buildWorldState(npc, { heavyScan = true })
	-- valid when player is visible/hostile
	return ws.isTargetVisible == true
end

function KillPlayer_Goal.getDesiredState()
	return { isTargetDead = true }
end

function KillPlayer_Goal.priority()
	return 10
end

return KillPlayer_Goal
