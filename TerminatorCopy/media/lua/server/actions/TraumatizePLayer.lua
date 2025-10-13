local TraumatizePlayer = {
    name            = "Traumatize player",
    preconditions   = {playerAFK = true, playerOnMaps = true, playerSittingOnGround = true, playerLooting = true},
    effects         = {injurePlayer = true},
    cost            = 5,
    perform         = function()
        
    end
}