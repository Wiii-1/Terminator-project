local HuntPlayer = {
    name            = "Hunt Player",
    preconditions   = {playerActivity = true, hasWeapon = true},
    effects         = {caughtPlayer = true},
    cost            = 2,
    perform         = function(self, TerminatorAgent, WorldState)
                      
    end
}