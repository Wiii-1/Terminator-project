local TerminatorAgent = {
    name        = "Bernard",
    state       = {
        playerSeen      = false,
        playerNearBy    = false,
        hasWeapon       = false,
        health          = 700

        -- if ever may want pa tayo add na state ni bernard
    },
    plan = nil,
    currentGoal = nil,
    actions = {},

    sense = function (self, world)
        -- di pa gawa yung world state eh
    end,

    planActions = function (self, goal)
        self.currentGoal    = goal
        self.plan           = goap_plan(self.state, self.actions, goal)
    end,

    executePlan = function (self, world)
        if not self.plan or #self.plan == 0 then return end
        local nextAction = self.plan[1]
        local success = nextAction:perform(self, world)
        if success then
            table.remove(self.plan, 1)
        end
    end
}

return TerminatorAgent