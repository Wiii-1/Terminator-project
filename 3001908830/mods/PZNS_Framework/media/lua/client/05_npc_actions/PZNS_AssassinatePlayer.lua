local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

--- Attempt stealth assassination of a player
---@param npcSurvivor PZNS_NPCSurvivor
---@param targetPlayer IsoPlayer The player to assassinate
function PZNS_AssassinatePlayer(npcSurvivor, targetPlayer)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return
    end
    
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    
    if not targetPlayer or targetPlayer:isDead() then
        print("[AssassinatePlayer] Target is invalid or dead")
        return
    end
    
    local npcX, npcY = npcIsoPlayer:getX(), npcIsoPlayer:getY()
    local targetX, targetY = targetPlayer:getX(), targetPlayer:getY()
    local distance = math.sqrt((targetX - npcX)^2 + (targetY - npcY)^2)
    
    -- Check if player can see us (simple LOS check)
    local canPlayerSeeNPC = targetPlayer:CanSee(npcIsoPlayer)
    
    -- If player can see us and we're far, stalk first
    if canPlayerSeeNPC and distance > 3 then
        print("[AssassinatePlayer] Player can see us, approaching stealthily")
        -- Move in shadows/around corners if possible
        local targetSquare = getCell():getGridSquare(targetX, targetY, targetPlayer:getZ())
        if targetSquare then
            local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, targetSquare)
            PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
        end
        return
    end
    
    -- Close enough and stealthy - perform assassination
    if distance <= 3 then
        -- Equip best melee weapon for silent kill
        local inventory = npcIsoPlayer:getInventory()
        local bestWeapon = nil
        local bestDamage = 0
        
        for i = 0, inventory:getItems():size() - 1 do
            local item = inventory:getItems():get(i)
            if item:IsWeapon() and instanceof(item, "HandWeapon") then
                local damage = item:getMaxDamage()
                -- Prefer melee for stealth
                if not item:isRanged() and damage > bestDamage then
                    bestWeapon = item
                    bestDamage = damage
                end
            end
        end
        
        if bestWeapon then
            npcIsoPlayer:setPrimaryHandItem(bestWeapon)
            npcIsoPlayer:setSecondaryHandItem(bestWeapon)
            print("[AssassinatePlayer] Equipped weapon for assassination:", bestWeapon:getName())
        end
        
        -- Set target and attack
        npcIsoPlayer:setTargetSeenTime(100) -- Max awareness
        npcIsoPlayer:setTarget(targetPlayer)
        
        -- Enable attack mode
        if npcSurvivor.aimTarget then
            npcSurvivor.aimTarget = targetPlayer
        end
        if npcSurvivor.canAttack ~= nil then
            npcSurvivor.canAttack = true
        end
        
        -- Move to kill range and attack
        local targetSquare = targetPlayer:getSquare()
        if targetSquare then
            local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, targetSquare)
            PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
            print("[AssassinatePlayer] Moving in for the kill")
        end
        
    else
        -- Approach target stealthily
        print("[AssassinatePlayer] Approaching target (distance:", distance, ")")
        local approachSquare = getCell():getGridSquare(targetX, targetY, targetPlayer:getZ())
        if approachSquare then
            local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, approachSquare)
            PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
        end
    end
end

return { PZNS_AssassinatePlayer = PZNS_AssassinatePlayer }
