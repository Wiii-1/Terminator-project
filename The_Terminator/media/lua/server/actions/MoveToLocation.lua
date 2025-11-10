
local MoveToLocation = {
    name = "MoveToLocation",
    preconditions = { playerSeen = true },
    effects = { followingPlayer = true },
    cost = 1,
    perform = function(self, agent, world)
        if not world or not world.playerPosition then
            print("[Action] MoveToLocation failed: no player position")
            return false
        end

        local npc = agent.character
        if not npc then
            return false
        end

        local playerX = world.playerPosition.x
        local playerY = world.playerPosition.y
        
        local npcX = npc:getX()
        local npcY = npc:getY()

        local dx = playerX - npcX
        local dy = playerY - npcY
        local distance = math.sqrt(dx*dx + dy*dy)

        if distance < 2 then
            return true  -- Close enough
        end

        dx = (dx / distance)
        dy = (dy / distance)

        npc:setX(npcX + dx)
        npc:setY(npcY + dy)

        return true
    end
}

return MoveToLocation
