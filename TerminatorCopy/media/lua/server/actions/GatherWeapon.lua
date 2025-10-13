local GatherWeapon = {
    name            =  "Gather Weapons",
    preconditions   =  {foundWeapon = true, weaponInGoodCondition = true},
    effects         =  {pickUpWeapon = true ,storedWeapon = true},
    cost            = 3,
    perform         = function (self, TerminatorAgent, WorldState)
        
    end
}