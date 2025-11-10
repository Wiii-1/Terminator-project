local WorldState = {
    -- Player InventoryItemFactory
    playerPosition          = nil,
    playerSeen              = false,
    playerNearBy            = false,
    playerHealthLow         = false,
    playerActivity          = false,

    -- Terminator internal status
    hasWeapon               = false,
    weaponConditiongood     = true,
    health                  = 700,
    location                = nil,

    -- Environtment Info 
    weaponNearby            = {},
    playerBaseSeen          = false,
    baseGeneratorActive     = false,

    -- Event Flags
    playerSwarmed           = false,
    playerInPanic           = false,

    -- Action results and WorldState
    storedWeapon            = false,
    followingPlayer         = false,
    caughtPlayer            = false,

    -- other Facts
    playerOnMaps            = false,
    playerAFK               = false,
    playerLooting           = false,
}

return WorldState