local GatherWeapon = {
    name            =  "Gather Weapons",
    preconditions   =  { foundWeapon = true, weaponInGoodCondition = true },
    effects         =  { pickUpWeapon = true, storedWeapon = true, hasWeapon = true },
    cost            = 3,
    perform         = function(self, agent, world)
        -- stub: pick up nearby weapon if world indicates one
        if world and world.weaponNearby and #world.weaponNearby > 0 then
            agent.state.hasWeapon = true
            agent.state.storedWeapon = true
            print("[Action] GatherWeapon: weapon obtained")
            return true
        end
        print("[Action] GatherWeapon failed")
        return false
    end
}

return GatherWeapon