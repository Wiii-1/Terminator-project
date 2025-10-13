local AssassinatePlayer = {
    name            = "Assassinate Player",
    preconditions   = {playerSwarmed = true, playerLowHealth = true, playerInPanic = true},
    effects         = {killPlayer = true},
    cost            = 8,
    perform         = function ()
        
    end
}