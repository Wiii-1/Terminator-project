local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
-- movement wrappers (may be missing — safe pcall)
local okRun, PZNS_RunTo = pcall(require, "05_npc_actions/PZNS_RunTo")
local okWalk, PZNS_WalkTo = pcall(require, "05_npc_actions/PZNS_WalkTo")

local GOAP_Hunt_Player = {}
GOAP_Hunt_Player.name = "GOAP_Hunt_Player"

setmetatable(GOAP_Hunt_Player, { __index = (require("05_npc_actions/PZNS_GOAP_Actions") or {}) })


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
        hasReachedWalkToLocation = true
    }
end

-- RUNTIME: perform does live queries and enqueues pathfinding (safe to call buildWorldState / getSpecificPlayer here)
-- return true when finished, false while moving
function GOAP_Hunt_Player:perform(npcSurvivor, targetID, delta)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return true
    end

    local npcIso = npcSurvivor.npcIsoPlayerObject
    if not npcIso then return true end

    -- resolve live player (singleplayer fallback)
    local targetIso = nil
    if type(targetID) == "string" and targetID:match("^Player") then
        targetIso = getSpecificPlayer(0)
    end
    if not targetIso and type(PZNS_UtilsNPCs.GetNearestIsoPlayerToNPC) == "function" then
        targetIso = PZNS_UtilsNPCs.GetNearestIsoPlayerToNPC(npcSurvivor)
    end
    if not targetIso then targetIso = getSpecificPlayer(0) end
    if not targetIso or type(targetIso.getX) ~= "function" then
        return true
    end

    local tx, ty, tz = targetIso:getX(), targetIso:getY(), targetIso:getZ()
    local px, py = npcIso:getX(), npcIso:getY()
    local dx, dy = tx - px, ty - py
    local distance = math.sqrt(dx*dx + dy*dy)

    local runThreshold = 6.0
    local reachThreshold = 1.8

    if distance <= reachThreshold then
        return true
    end

    if distance > runThreshold and okRun and type(PZNS_RunTo.execute) == "function" then
        pcall(PZNS_RunTo.execute, PZNS_RunTo, npcSurvivor, tx, ty, tz)
    elseif okWalk and type(PZNS_WalkTo.execute) == "function" then
        pcall(PZNS_WalkTo.execute, PZNS_WalkTo, npcSurvivor, tx, ty, tz)
    else
        -- fallback: queue a simple WalkTo timed action
        local sq = getCell():getGridSquare(tx, ty, tz)
        if sq then
            local walkAction = ISWalkToTimedAction:new(npcIso, sq)
            walkAction.npcSurvivor = npcSurvivor
            -- queue helper from your utils (if available)
            if type(PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue) == "function" then
                PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
            end
        end
    end

    return false
end

return GOAP_Hunt_Player
