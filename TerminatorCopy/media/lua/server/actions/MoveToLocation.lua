local Pathfinding = require("server.TerminatorPathfinding")

local MoveToLocation = {
    name = "MoveToLocation",
    preconditions = { playerSeen = true },
    effects = {
        followingPlayer = true,
        location = function(state) return state and state.playerPosition or nil end
    },
    cost = 1,
    perform = function(self, agent, world)
        if not world or not world.playerPosition then
            print("[Action] MoveToLocation failed: no player position")
            return false
        end

        if not agent.navigationGraph then
            agent:buildNavigationGraph()
        end

        local startX, startY, startZ = agent.state.x or 0, agent.state.y or 0, agent.state.z or 0
        local endX, endY, endZ = world.playerPosition.x, world.playerPosition.y, world.playerPosition.z or 0

        local startNode = string.format("%d,%d,%d", startX, startY, startZ)
        local endNode = string.format("%d,%d,%d", endX, endY, endZ)

        local path = Pathfinding.dijkstra(agent.navigationGraph, startNode, endNode)
        if not path then
            print("[Action] MoveToLocation failed: no path found")
            return false
        end

        local nextStep = path[2] or path[1]
        if nextStep then
            local x, y, z = nextStep:match("(%d+),(%d+),(%d+)")
            agent.state.x = tonumber(x)
            agent.state.y = tonumber(y)
            agent.state.z = tonumber(z)
            print(string.format("[Action] Moved to %d,%d,%d", agent.state.x, agent.state.y, agent.state.z))
            return true
        end
        return false
    end
}

return MoveToLocation