local StalkPlayer = {
    name            = "Stalk Player",
    preconditions   = { playerSeen = true, playerNearBy = true },
    effects         = { followingPlayer = true },
    cost            = 3,
    perform         = function(self, agent, world)
        -- stub: set following flag
        if agent.state.playerSeen then
            agent.state.followingPlayer = true
            print("[Action] StalkPlayer performed")
            return true
        end
        print("[Action] StalkPlayer failed")
        return false
    end
}

return StalkPlayer