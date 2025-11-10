local AssassinatePlayer = {
    name            = "Assassinate Player",
    preconditions   = { playerSwarmed = true, playerLowHealth = true, playerInPanic = true },
    effects         = { killPlayer = true },
    cost            = 8,
    perform         = function(self, agent, world)
        if agent.state.playerSwarmed and agent.state.playerInPanic then
            print("[Action] AssassinatePlayer performed (stub)")
            return true
        end
        print("[Action] AssassinatePlayer failed")
        return false
    end
}

return AssassinatePlayer