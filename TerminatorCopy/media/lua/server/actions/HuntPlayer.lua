local HuntPlayer = {
    name            = "HuntPlayer",
    preconditions   = { playerActivity = true, hasWeapon = true },
    effects         = { caughtPlayer = true },
    cost            = 2,
    perform         = function(self, agent, world)
        -- minimal stub: if agent hasWeapon and sees player, succeed and set state
        if agent.state.hasWeapon and (agent.state.playerSeen or (world and world.playerSeen)) then
            agent.state.caughtPlayer = true
            print("[Action] HuntPlayer succeeded")
            return true
        end
        print("[Action] HuntPlayer failed")
        return false
    end
}

return HuntPlayer