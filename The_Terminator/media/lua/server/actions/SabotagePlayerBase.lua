local SabotagePlayerBase = {
    name            = "Sabotage Player Base",
    preconditions   = { playerBaseSeen = true, playerAbsent = true, generatorSeen = true },
    effects         = { ruinBaseGenerator = true, setPlayerbaseOnFire = true },
    cost            = 7,
    perform         = function(self, agent, world)
        -- stub: if base seen and generator active then succeed
        if agent.state.playerBaseSeen and (world and world.generatorSeen) then
            print("[Action] SabotagePlayerBase performed")
            return true
        end
        print("[Action] SabotagePlayerBase failed")
        return false
    end
}

return SabotagePlayerBase