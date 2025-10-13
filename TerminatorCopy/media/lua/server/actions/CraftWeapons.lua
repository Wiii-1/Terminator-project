local CraftWeapons = {
    name            = "Craft Weapons",
    preconditions   = {hasWeapon = false, hasMaterial = true},
    effects         = {craftedWeapon = true, storedWeapon = true},
    cost            = 5,
    perform         = function(self, TerminatorAgent, WorldState)
        
    end

}