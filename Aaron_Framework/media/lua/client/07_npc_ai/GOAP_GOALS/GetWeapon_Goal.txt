-- ...existing code...
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local Goal = require("07_npc_ai/PZNS_Goal")

local GetWeapon_Goal = {}
GetWeapon_Goal.name = "GetWeapon_Goal"

setmetatable(GetWeapon_Goal, { __index = Goal })

function GetWeapon_Goal.isValid(npc)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npc) then return false end
    local ws = PZNS_GOAPWorldState.buildWorldState(npc, { heavyScan = false })
    -- valid when NPC does not currently have an equipped weapon
    return not ws.hasWeaponEquipped
end

function GetWeapon_Goal.getDesiredState()
    return { hasWeaponEquipped = true }
end

function GetWeapon_Goal.priority(npc)
    local ws = PZNS_GOAPWorldState.buildWorldState(npc, { heavyScan = false })
    return ws.hasWeaponEquipped and 0 or 5
end

return GetWeapon_Goal