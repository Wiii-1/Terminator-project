local function deepcopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k,v in pairs(orig) do
        copy[deepcopy(k)] = deepcopy(v)
    end
    return copy
end

local function heuristic(state, goal)
    local h = 0
    for k, v in pairs(goal) do
        if state[k] ~= v then h = h + 1 end
    end
    return h
end

local function stateHash(state)
    -- simple deterministic serialization for primitive-valued state tables
    local keys = {}
    for k in pairs(state) do table.insert(keys, tostring(k)) end
    table.sort(keys)
    local parts = {}
    for _,k in ipairs(keys) do
        local v = state[k]
        parts[#parts+1] = tostring(k).."="..tostring(v)
    end
    return table.concat(parts, ";")
end

local function isGoalSatisfied(state, goal)
    for k,v in pairs(goal) do
        if state[k] ~= v then return false end
    end
    return true
end

local function isApplicable(action, state)
    if not action or not action.preconditions then return true end
    for k,v in pairs(action.preconditions) do
        if type(v) == "function" then
            if not v(state) then return false end
        else
            if state[k] ~= v then return false end
        end
    end
    return true
end

function goap_plan(StartState, actions, goal)
    local open = {
        { state = deepcopy(StartState), plan = {}, g = 0, h = heuristic(StartState, goal) }
    }
    local closed = {}

    while #open > 0 do
        table.sort(open, function(a,b) return (a.g + a.h) < (b.g + b.h) end)
        local node = table.remove(open, 1)

        local nodeHash = stateHash(node.state)
        if isGoalSatisfied(node.state, goal) then
            return node.plan
        end

        -- record best g for this state to avoid re-expansion
        if closed[nodeHash] and closed[nodeHash] <= node.g then
            -- already found a better or equal path
        else
            closed[nodeHash] = node.g

            for _, action in ipairs(actions) do
                if isApplicable(action, node.state) then
                    local newState = deepcopy(node.state)
                    if action.effects then
                        for k,v in pairs(action.effects) do
                            -- effect can be function or direct assignment
                            if type(v) == "function" then
                                newState[k] = v(newState)
                            else
                                newState[k] = v
                            end
                        end
                    end

                    local tentative_g = node.g + (action.cost or 1)
                    local newHash = stateHash(newState)
                    if closed[newHash] and closed[newHash] <= tentative_g then
                        -- skip worse path
                    else
                        local newPlan = {}
                        for i,step in ipairs(node.plan) do newPlan[i] = step end
                        table.insert(newPlan, action)
                        table.insert(open, {
                            state = newState,
                            plan  = newPlan,
                            g     = tentative_g,
                            h     = heuristic(newState, goal)
                        })
                    end
                end
            end
        end
    end

    return nil
end