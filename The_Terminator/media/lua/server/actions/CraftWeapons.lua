local CraftWeapons = {
    name            = "Craft Weapons",
    preconditions   = { hasWeapon = false, hasMaterial = true },
    effects         = { craftedWeapon = true, storedWeapon = true, hasWeapon = true },
    cost            = 5,
    perform         = function(self, agent, world)
        -- craft if materials present
        if world and world.hasMaterial then
            agent.state.hasWeapon = true
            agent.state.craftedWeapon = true
            print("[Action] CraftWeapons succeeded")
            return true
        end
        print("[Action] CraftWeapons failed")
        return false
    end
}

return CraftWeapons