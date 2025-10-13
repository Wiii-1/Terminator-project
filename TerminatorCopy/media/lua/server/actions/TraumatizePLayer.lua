local TraumatizePlayer = {
    name            = "Traumatize player",
    preconditions   = { playerAFK = true, playerOnMaps = true, playerSittingOnGround = true, playerLooting = true },
    effects         = { injurePlayer = true },
    cost            = 5,
    perform         = function(self, agent, world)
        if agent.state.playerAFK then
            print("[Action] TraumatizePlayer performed")
            return true
        end
        print("[Action] TraumatizePlayer failed")
        return false
    end
}

return TraumatizePlayer