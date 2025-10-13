local Planner = require("TerminatorPlanner")
local WorldState = require("shared.WorldState")

-- require action modules (server.actions.*)
local HuntPlayer        = require("server.actions.HuntPlayer")
local GatherWeapon      = require("server.actions.GatherWeapon")
local CraftWeapons      = require("server.actions.CraftWeapons")
local StalkPlayer       = require("server.actions.StalkPlayer")
local SabotagePlayerBase= require("server.actions.SabotagePlayerBase")
local TraumatizePlayer  = require("server.actions.TraumatizePLayer")
local AssassinatePlayer = require("server.actions.AssassinatePlayer")
local MoveToLocation    = require("server.actions.MoveToLocation") -- stub for movement

local TerminatorAgent = {
    name        = "Bernard",
    state       = {
        playerSeen      = false,
        playerNearBy    = false,
        hasWeapon       = false,
        health          = 700,
        location        = nil
    },
    plan = nil,
    currentGoal = nil,
    actions = {
        MoveToLocation,
        HuntPlayer,
        GatherWeapon,
        CraftWeapons,
        StalkPlayer,
        SabotagePlayerBase,
        TraumatizePlayer,
        AssassinatePlayer
    },

    sense = function (self, world)
        -- minimal sense: copy small facts from global WorldState or provided world table
        -- keep the agent-local state small (only facts used by planner)
        if world then
            self.state.playerSeen   = world.playerSeen or self.state.playerSeen
            self.state.playerNearBy = world.playerNearBy or self.state.playerNearBy
            self.state.hasWeapon    = world.hasWeapon or self.state.hasWeapon
            self.state.location     = world.location or self.state.location
        end
    end,

    planActions = function (self, goal, opts)
        self.currentGoal = goal
        local startState = Planner.deepcopy(self.state)
        if opts and opts.verbose then print("[Agent] planning from state:", Planner.stateHash(startState)) end
        self.plan = Planner.goap_plan(startState, self.actions, goal, opts or { verbose = false })
        if self.plan then
            print("[Agent] plan found. length:", #self.plan)
            for i,a in ipairs(self.plan) do print(string.format("[Agent] plan[%d]=%s", i, a.name or "<unnamed>")) end
        else
            print("[Agent] no plan found for goal")
        end
    end,

    executePlan = function (self, world)
        if not self.plan or #self.plan == 0 then return end
        local nextAction = self.plan[1]
        print("[Agent] executing action:", nextAction.name or "<unnamed>")
        local ok = false
        if nextAction.perform then
            ok = nextAction.perform(nextAction, self, world)
        else
            ok = true
        end

        if ok then
            table.remove(self.plan, 1)
            if #self.plan == 0 and Planner.isGoalSatisfied(self.state, self.currentGoal) then
                print("[Agent] goal satisfied")
            end
        else
            print("[Agent] action failed, replanning")
            -- simple failure handling: replan from current state
            self:planActions(self.currentGoal, { verbose = true })
        end
    end
}

return TerminatorAgent