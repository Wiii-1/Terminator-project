local Planner           = require("TerminatorPlanner")
local WorldState        = require("shared.WorldState")
local BuildGraphFromMap = require("server.TerminatorPathGraph")
local Pathfinding = require("server.TerminatorPathfinding")


-- require action modules (server.actions.*)
local HuntPlayer        = require("server.actions.HuntPlayer")
local GatherWeapon      = require("server.actions.GatherWeapon")
local CraftWeapons      = require("server.actions.CraftWeapons")
local StalkPlayer       = require("server.actions.StalkPlayer")
local SabotagePlayerBase= require("server.actions.SabotagePlayerBase")
local TraumatizePlayer  = require("server.actions.TraumatizePLayer")
local AssassinatePlayer = require("server.actions.AssassinatePlayer")
local MoveToLocation    = require("server.actions.MoveToLocation") 

local TerminatorAgent = {
    name        = "Bern",
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
        if world then
            self.state.playerSeen   = world.playerSeen or self.state.playerSeen
            self.state.playerNearBy = world.playerNearBy or self.state.playerNearBy
            self.state.hasWeapon    = world.hasWeapon or self.state.hasWeapon
            self.state.location     = world.location or self.state.location
        end
    end,

    buildNavigationGraph = function (self)
        local width, height, z = 300, 300, self.state.z or 0 -- Adjust map size
        self.navigationGraph = {}
    
        for x = 1, width do
            for y = 1, height do
                local sq = getCell():getGridSquare(x, y, z)
                if sq and sq:isFree(true) then
                    local node = string.format("%d,%d,%d", x, y, z)
                    self.navigationGraph[node] = {}
                
                -- Connect to adjacent nodes
                    for dx = -1, 1 do
                        for dy = -1, 1 do
                            if (dx ~= 0 or dy ~= 0) and math.abs(dx) + math.abs(dy) <= 1 then
                                local nx, ny = x + dx, y + dy
                                local nsq = getCell():getGridSquare(nx, ny, z)
                                if nsq and nsq:isFree(true) then
                                    local neighbor = string.format("%d,%d,%d", nx, ny, z)
                                    self.navigationGraph[node][neighbor] = 1
                                end
                            end
                        end
                    end
                end
            end
        end
        print("[Path] Navigation graph built with " .. table.size(self.navigationGraph) .. " nodes")
    end
,

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
            self:planActions(self.currentGoal, { verbose = true })
        end
    end
}

return TerminatorAgent