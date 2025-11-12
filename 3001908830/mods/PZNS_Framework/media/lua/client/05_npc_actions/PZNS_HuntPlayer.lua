local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

--- Hunt and pursue the player target
---@param npcSurvivor PZNS_NPCSurvivor
---@param targetPlayer IsoPlayer
function PZNS_HuntPlayer(npcSurvivor, targetPlayer)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return
    end
    
    if not targetPlayer or not targetPlayer:isAlive() then
        print("[HuntPlayer] No valid target player")
        return
    end
    
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    
    -- Get target position
    local targetX = targetPlayer:getX()
    local targetY = targetPlayer:getY()
    local targetZ = targetPlayer:getZ()
    
    -- Calculate distance
    local npcX = npcIsoPlayer:getX()
    local npcY = npcIsoPlayer:getY()
    local dx = targetX - npcX
    local dy = targetY - npcY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- If close enough, engage in combat
    if distance < 2 then
        npcSurvivor.aimTarget = targetPlayer
        npcSurvivor.canAttack = true
        npcIsoPlayer:NPCSetAiming(true)
        print("[HuntPlayer] Engaging target at close range")
    else
        -- Move toward target
        local targetSquare = getCell():getGridSquare(targetX, targetY, targetZ)
        if targetSquare then
            -- Use running for pursuit
            npcIsoPlayer:NPCSetRunning(true)
            local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, targetSquare)
            PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
            print(string.format("[HuntPlayer] Pursuing target at distance %.1f", distance))
        end
    end
end

return { PZNS_HuntPlayer = PZNS_HuntPlayer }
