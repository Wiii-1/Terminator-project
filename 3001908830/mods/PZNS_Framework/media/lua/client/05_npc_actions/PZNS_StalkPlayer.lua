local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

--- Stalk the player from a distance without being detected
---@param npcSurvivor PZNS_NPCSurvivor
---@param targetPlayer IsoPlayer
---@param stalkDistance number Distance to maintain from target (default: 10)
function PZNS_StalkPlayer(npcSurvivor, targetPlayer, stalkDistance)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return
    end
    
    if not targetPlayer or not targetPlayer:isAlive() then
        print("[StalkPlayer] No valid target player")
        return
    end
    
    stalkDistance = stalkDistance or 10
    
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    
    -- Get target position
    local targetX = targetPlayer:getX()
    local targetY = targetPlayer:getY()
    local targetZ = targetPlayer:getZ()
    
    -- Calculate distance and direction
    local npcX = npcIsoPlayer:getX()
    local npcY = npcIsoPlayer:getY()
    local dx = targetX - npcX
    local dy = targetY - npcY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- If too close, back away
    if distance < stalkDistance - 2 then
        -- Move away from target
        local awayX = npcX - (dx / distance) * 3
        local awayY = npcY - (dy / distance) * 3
        local awaySquare = getCell():getGridSquare(awayX, awayY, targetZ)
        
        if awaySquare then
            npcIsoPlayer:NPCSetRunning(false) -- Walk when backing away
            local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, awaySquare)
            PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
            print("[StalkPlayer] Backing away - too close to target")
        end
    -- If too far, move closer
    elseif distance > stalkDistance + 2 then
        -- Calculate position at stalk distance
        local stalkX = targetX - (dx / distance) * stalkDistance
        local stalkY = targetY - (dy / distance) * stalkDistance
        local stalkSquare = getCell():getGridSquare(stalkX, stalkY, targetZ)
        
        if stalkSquare then
            npcIsoPlayer:NPCSetRunning(false) -- Walk when stalking
            local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, stalkSquare)
            PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
            print(string.format("[StalkPlayer] Stalking at distance %.1f", distance))
        end
    else
        -- Maintain position and observe
        print("[StalkPlayer] Maintaining stalk distance")
    end
end

return { PZNS_StalkPlayer = PZNS_StalkPlayer }
