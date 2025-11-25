local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local PZNS_GOAP_Actions = require("05_npc_actions/PZNS_GOAP_Actions")


local PZNS_GOAP_Walk_to = {};
PZNS_GOAP_Walk_to.name = "PZNS_GOAP_Walk_to";

setmetatable(PZNS_GOAP_Walk_to, { __index = PZNS_GOAP_Actions });

function PZNS_GOAP_Walk_to:isValid(npc, targetSquare)
    return PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npc) and targetSquare ~= nil;
end

function PZNS_GOAP_Walk_to:cost()
    return 1.0;
end

function PZNS_GOAP_Walk_to:getPreconditions()
    return { isTargetInFollowRange = true, isWalkToLocationAvailable = true };
end

function PZNS_GOAP_Walk_to:getEffects()
    return { hasReachedWalkToLocation = true };
end


function PZNS_GOAP_Walk_to:perform(npcSurvivor, targetSquare)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        print("PZNS_GOAP_Walk_to: invalid npcSurvivor")
        return true
    end

    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    if not npcIsoPlayer or not targetSquare then
        return true
    end

    -- get target coordinates
    local tx, ty, tz = targetSquare:getX(), targetSquare:getY(), targetSquare:getZ()
    local px, py = npcIsoPlayer:getX(), npcIsoPlayer:getY()

    local dx, dy = tx - px, ty - py
    local distance = math.sqrt(dx * dx + dy * dy)

    -- safe follow range lookup (fallback to 20)
    local followRange = 20
    if type(PZNS_UtilsNPCs.TerminatorFollowRange) == "function" then
        local ok, r = pcall(PZNS_UtilsNPCs.TerminatorFollowRange, npcSurvivor)
        if ok and type(r) == "table" and type(r.walk) == "number" then
            followRange = r.walk
        end
    end

    local reachThreshold = 1.8

    if distance <= math.min(followRange, reachThreshold) then
        return true
    end

    -- queue walking action and set NPC state
    npcSurvivor:PZNS_WalkToSquareXYZ(tx, ty, tz)
    npcSurvivor.currentAction = "Walking"
    if type(npcSurvivor.NPCSetRunnning) == "function" then
        npcSurvivor:NPCSetRunnning(false)
    end

    local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, targetSquare)
    if type(PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue) == "function" then
        PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
    end

    return false
end