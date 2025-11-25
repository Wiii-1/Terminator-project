local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")
local PZNS_GOAP_Actions = require("05_npc_actions/PZNS_GOAP_Actions")


local PZNS_GOAP_Walk_to = {};
PZNS_GOAP_Walk_to.name = "PZNS_GOAP_Walk_to";

setmetatable(PZNS_GOAP_Walk_to, { __index = PZNS_GOAP_Actions });

function PZNS_GOAP_Walk_to:isValid(npc, targetSquare)
    local npcIsoPlayer = npcSuvivor.npcIsoPlayerObject
    local ws = PZNS_GOAPWorldState.buildWorldState(npc, { heavyScan = false })
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npc) then return false end
    if targetSquare == nil then return false end
    return ws.isTargetInFollowRange and ws.hasReachedWalkToLocation
end

function PZNS_GOAP_Walk_to:cost(npc, targetSquare)
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
    local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor, { heavyScan = true })
    local TerminatorFollowRange = PZNS_UtilsNPCs.TerminatorFollowRange(npcSurvivor)
    
    if ws.distanceFromTarget <= TerminatorFollowRange.walk then
        return true
    else
        npcSurvivor:PZNS_WalkToSquareXYZ(targetSquare:getX(), targetSquare:getY(), targetSquare:getZ())
        npcSurvivor.currentAction = "Walking"
        npcSurvivor:NPCSetRunnning(false)
        local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, targetSquare);
        PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction);
        return false
    end
end