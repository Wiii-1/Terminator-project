local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

--- Sabotage player's base by breaking windows, destroying containers, etc.
---@param npcSurvivor PZNS_NPCSurvivor
---@param targetSquare IsoGridSquare Square to sabotage (default: NPC's current square)
function PZNS_SabotagePlayerBase(npcSurvivor, targetSquare)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return
    end
    
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    
    -- Use current square if no target specified
    if not targetSquare then
        targetSquare = npcIsoPlayer:getSquare()
    end
    
    if not targetSquare then
        print("[SabotagePlayerBase] No valid square to sabotage")
        return
    end
    
    -- Look for objects to sabotage
    local objects = targetSquare:getObjects()
    
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        
        -- Break windows
        if obj:getSprite() and obj:getSprite():getName() and 
           (obj:getSprite():getName():contains("window") or obj:getSprite():getName():contains("Window")) then
            if instanceof(obj, "IsoWindow") and not obj:isSmashed() then
                obj:smashWindow()
                print("[SabotagePlayerBase] Smashed window")
                return
            end
        end
        
        -- Destroy containers
        if instanceof(obj, "IsoThumpable") and obj:canBeRemoved() then
            obj:destroy()
            print("[SabotagePlayerBase] Destroyed object:", obj:getObjectName())
            return
        end
        
        -- Break down doors
        if instanceof(obj, "IsoDoor") and not obj:IsOpen() then
            obj:ToggleDoor(npcIsoPlayer)
            print("[SabotagePlayerBase] Opened door")
            return
        end
    end
    
    -- If nothing to sabotage at current location, move to nearby square
    local nearbySquares = {}
    for dx = -2, 2 do
        for dy = -2, 2 do
            if dx ~= 0 or dy ~= 0 then
                local sq = getCell():getGridSquare(
                    targetSquare:getX() + dx,
                    targetSquare:getY() + dy,
                    targetSquare:getZ()
                )
                if sq then
                    table.insert(nearbySquares, sq)
                end
            end
        end
    end
    
    if #nearbySquares > 0 then
        local randomSquare = nearbySquares[ZombRand(#nearbySquares) + 1]
        local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, randomSquare)
        PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction)
        print("[SabotagePlayerBase] Moving to find targets to sabotage")
    else
        print("[SabotagePlayerBase] No sabotage targets found")
    end
end

return { PZNS_SabotagePlayerBase = PZNS_SabotagePlayerBase }
