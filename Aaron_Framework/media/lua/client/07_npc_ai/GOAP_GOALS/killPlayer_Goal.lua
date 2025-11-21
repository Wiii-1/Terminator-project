-- ...existing code...
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local Goal = require("07_npc_ai/PZNS_Goal")

local KillPlayer_Goal = {}
KillPlayer_Goal.name = "KillPlayer_Goal"

setmetatable(KillPlayer_Goal, { __index = Goal })

function KillPlayer_Goal.isValid(npc)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npc) then return false end
    local ws = PZNS_GOAPWorldState.buildWorldState(npc, { heavyScan = true })
    -- valid when player is visible/hostile
    return ws.isPlayerVisible == true
end

function KillPlayer_Goal.getDesiredState()
    return { isPlayerDead = true }
end

function KillPlayer_Goal.priority(npc)
    local ws = PZNS_GOAPWorldState.buildWorldState(npc, { heavyScan = true })
    return ws.isPlayerVisible and 10 or 0
end

return KillPlayer_Goal