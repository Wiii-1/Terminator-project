local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local PZNS_GOAP_Actions = require("05_npc_actions/PZNS_GOAP_Actions")


-- added movement action wrappers
local okRun, PZNS_RunTo = pcall(require, "05_npc_actions/PZNS_RunTo")
local okWalk, PZNS_WalkTo = pcall(require, "05_npc_actions/PZNS_WalkTo")

local GOAP_Hunt_Player = {};
GOAP_Hunt_Player.name = "GOAP_Hunt_Player";

setmetatable(GOAP_Hunt_Player, { __index = PZNS_GOAP_Actions });

function GOAP_Hunt_Player:isValid(npc, targetID)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npc) then return false end
    local ok, ws = pcall(PZNS_GOAPWorldState.buildWorldState, npc, { heavyScan = false })
    if not ok or type(ws) ~= "table" then return false end
    return not (ws.isTargetVisible == true or ws.isPlayerVisible == true)
end

function GOAP_Hunt_Player:cost(npc, targetID)
    return 7.0;
end

function GOAP_Hunt_Player:getPreconditions()
    return { isTargetVisible = false };
end

function GOAP_Hunt_Player:getEffects()
    return { hasReachedPlayer = true };
end

-- perform: if player visible, move NPC toward player (run if far, walk if near)
function GOAP_Hunt_Player:perform(npcSurvivor, targetID, delta)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        print("GOAP_Hunt_Player: invalid npcSurvivor")
        return true
    end

    local ok, ws = pcall(PZNS_GOAPWorldState.buildWorldState, npcSurvivor, { heavyScan = true })
    if not ok or type(ws) ~= "table" then
        print("GOAP_Hunt_Player: buildWorldState error ->", tostring(ws))
        return false
    end

    local visible = (ws.isTargetVisible == true) or (ws.isPlayerVisible == true)
    print("GOAP_Hunt_Player: player visible according to worldstate ->", tostring(visible))

    if not visible then
        return false
    end

    -- resolve iso player (singleplayer fallback)
    local targetIso = nil
    if type(targetID) == "string" and targetID:match("^Player") then
        targetIso = getSpecificPlayer(0)
    end
    if not targetIso and type(PZNS_UtilsNPCs.GetNearestIsoPlayerToNPC) == "function" then
        targetIso = PZNS_UtilsNPCs.GetNearestIsoPlayerToNPC(npcSurvivor)
    end
    if not targetIso then
        targetIso = getSpecificPlayer(0) -- last resort
    end
    if not targetIso or type(targetIso.getX) ~= "function" then
        print("GOAP_Hunt_Player: could not resolve target IsoPlayer")
        return false
    end

    local npcIso = npcSurvivor.npcIsoPlayerObject
    if not npcIso then return false end

    local tx, ty, tz = targetIso:getX(), targetIso:getY(), targetIso:getZ()
    local px, py = npcIso:getX(), npcIso:getY()

    local function dist(ax, ay, bx, by)
        local dx, dy = ax - bx, ay - by
        return math.sqrt(dx*dx + dy*dy)
    end

    local distance = dist(px, py, tx, ty)

    -- thresholds (tweak to taste)
    local runThreshold = 6.0
    local reachThreshold = 1.8

    -- choose RunTo or WalkTo if available; call safely
    if distance > runThreshold then
        if okRun and type(PZNS_RunTo.execute) == "function" then
            pcall(PZNS_RunTo.execute, PZNS_RunTo, npcSurvivor, tx, ty, tz)
        end
    else
        if okWalk and type(PZNS_WalkTo.execute) == "function" then
            pcall(PZNS_WalkTo.execute, PZNS_WalkTo, npcSurvivor, tx, ty, tz)
        end
    end

    -- return true when close enough to the player
    if distance <= reachThreshold then
        print("GOAP_Hunt_Player: reached player (distance=", distance, ")")
        return true
    end

    return false
end

return GOAP_Hunt_Player;
