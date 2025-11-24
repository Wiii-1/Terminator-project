local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils");
local PZNS_GOAPAction = require("07_npc_ai/PZNS_GOAPAction");

local GOAPHuntPlayer = {};
GOAPHuntPlayer.name = "GOAP_Hunt_Player";

setmetatable(GOAPHuntPlayer, { __index = PZNS_GOAPAction });

function GOAPHuntPlayer:isValid(npc, targetID)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npc) then return false end
    local ws = PZNS_WorldUtils.BuildNPCWorldState(npc, { heavyScan = false });
    return not ws.isPlayerVisible;
end

function GOAPHuntPlayer:cost(npc, targetID)
    return 7.0;
end

function GOAPHuntPlayer:getPreconditions()
    return { isPlayerVisible = false };
end

function GOAPHuntPlayer:getEffects()
    return { hasReachedPlayer = true };
end

function GOAPHuntPlayer:perform(npcSurvivor, targetID, delta)
    local LastKnown = require("02_mod_utils/PZNS_LastKnownLocation")
    local PZNS_RunTo = require("05_npc_actions/PZNS_RunTo")
    local PZNS_WalkTo = require("05_npc_actions/PZNS_WalkTo")

    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return true
    end
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject

    -- resolve target player (Player0 fallback)
    local targetPlayer = nil
    if type(targetID) == "string" and targetID:match("^Player") then
        targetPlayer = getSpecificPlayer(0)
    elseif type(PZNS_UtilsNPCs.GetIsoPlayerByID) == "function" then
        targetPlayer = PZNS_UtilsNPCs.GetIsoPlayerByID(targetID)
    end

    -- get last-known coords (prefer stored LastKnownLocation for that player)
    local tx, ty, tz
    if targetPlayer then
        local lk = LastKnown.get(targetPlayer)
        if lk then
            tx, ty, tz = lk.x, lk.y, lk.z
        else
            tx, ty, tz = targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ()
        end
        npcSurvivor.lastKnownPlayer = targetPlayer
        npcSurvivor.lastKnownPlayerX = tx
        npcSurvivor.lastKnownPlayerY = ty
        npcSurvivor.lastKnownPlayerZ = tz
    else
        -- fallback to client player's stored last location
        local client = getPlayer()
        local lk = client and LastKnown.get(client)
        if lk then tx,ty,tz = lk.x, lk.y, lk.z end
    end

    if not tx or not ty then
        -- nothing to hunt
        return true
    end

    -- distance helper
    local function dist(ax, ay, bx, by)
        local dx, dy = ax - bx, ay - by
        return math.sqrt(dx*dx + dy*dy)
    end

    local px, py = npcIsoPlayer:getX(), npcIsoPlayer:getY()
    local distanceToTarget = dist(px, py, tx, ty)

    -- choose movement action
    if distanceToTarget > 5 then
        PZNS_RunTo.execute(npcSurvivor, tx, ty, tz)
    else
        PZNS_WalkTo.execute(npcSurvivor, targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ())
    end

    -- complete when reached
    if distanceToTarget <= 2 then
        npcSurvivor.lastKnownPlayerX = nil
        npcSurvivor.lastKnownPlayerY = nil
        npcSurvivor.lastKnownPlayerZ = nil
        npcSurvivor.lastKnownPlayer = nil
        return true
    end

    return false
end
