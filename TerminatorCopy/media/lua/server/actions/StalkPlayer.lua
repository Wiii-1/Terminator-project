local StalkPlayer = {
    name            = "Stalk Player",
    preconditions   = {playerSeen = true, playerNearBy = true},
    effects         = {followingPlayer = true},
    cost            = 3,
    perform         = function()
        
    end
}