local SabotagePLayerBase = {
    name            = "Sabotage Player Base",
    preconditions   = {playerBaseSeen = true, playerAbsent = true, generatorSeen = true},
    effects         = {ruinBaseGenerator = true, setPlayerbaseOnFire = true},
    cost            = 7,
    perform         = function ()
        
    end
}