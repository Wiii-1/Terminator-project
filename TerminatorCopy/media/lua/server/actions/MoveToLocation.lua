local MoveToLocation = {
    name = "MoveToLocation",
    preconditions = { playerSeen = true },
    effects = {
        followingPlayer = true,
        -- effect can be a function to compute new value based on state
        location = function(state) return state and state.playerPosition or nil end
    },
    cost = 1,
    perform = function(self, agent, world)
        -- immediate stub: set agent location to player position (if available)
        if world and world.playerPosition then
            agent.state.location = world.playerPosition
            print("[Action] MoveToLocation performed: moved to", tostring(world.playerPosition))
            return true
        end
        print("[Action] MoveToLocation failed: no player position")
        return false
    end
}

return MoveToLocation