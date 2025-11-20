local PZNS_GOAPPlanner = {}

local actions = {
    require("05_npc_actions/PZNS_GOAPGunMagazine"),
    require("05_npc_actions/PZNS_GOAPHuntPlayer"),
    require("05_npc_actions/PZNS_GOAPPickUpWeapon"),
    require("05_npc_actions/PZNS_GOAPRunTo"),
    require("05_npc_actions/PZNS_GOAPScavenge"),
    require("05_npc_actions/PZNS_GOAPSwitchWeapon"),
    require("05_npc_actions/PZNS_GOAPWalkTo"),
    require("05_npc_actions/PZNS_GOAPWeaponAiming"),
    require("05_npc_actions/PZNS_GOAPWeaponAttack"),    
    require("05_npc_actions/PZNS_GOAPWeaponEquip"),
    require("05_npc_actions/PZNS_GOAPWeaponReload"),
}

local PZNS_GOAPWorldState = require("05_npc_actions/PZNS_GOAPWorldState")

local local_copyState = function(state)
    local newState = {}
    for k, v in pairs(state) do
        newState[k] = v
    end
    return newState
end

local local_meetsPreconditions = function(state, preconditions)
    if not preconditions then
        return true
    end
    for k, v in pairs(preconditions) do
        if state[k] ~= v then
            return false
        end
    end
    return true
end

local function local_applyEffects(state, effects)
    local ns = local_copyState(state)
    for k, v in pairs(effects) do
        ns[k] = v
    end
    return ns
end

local local_stateHash = function(state)
    local keys = {}
    for k,_ in pairs(state or {}) do table.insert(keys, k) end
    table.sort(keys)

    local parts = {}
    for _,k in ipairs(keys) do parts[#parts+1] = tostring(k) .. "=" .. tostring(state[k]) end
    return table.concat(parts, "|")
end

local local_heuristic = function(state, goalState)
    local cost = 0 
    for k, v in pairs (goalState or {}) do
        if state[k] ~= v then
            cost = cost + 1
        end
    end
    return cost
end

function PZNS_GOAPPlanner.plan(worldState, goalState, actions)

    local availableActions = actions or {}
    if not worldState or not goalState then 
        return nil 
    end

    local openSet = {}
    local closedSet = {}

    table.insert (openSet, {local_copyState(worldState), g = 0, h = local_heuristic(worldState, goalState), plan = {}})
    
    while #openSet > 0 do
        table.sort(openSet, function (a,b) return (a.g + a.h) < (b.g + b.h) end)
        local currentNode = table.remove(openSet, 1)

        if local_heuristic(currentNode.state, goalState) == 0 then
            return currentNode.plan
        end

        local stateHash = local_stateHash(currentNode.state)
        if closedSet[currentNode] then goto continue end
        closedSet[stateHash] = true

        for _, actions in ipairs(availableActions) do
            if actions and local_meetsPreconditions(currentNode.state, actions.preconditions) then
                local newState = local_applyEffects(currentNode.state, actions.effects)
                local newPlan = {}

                for i=1,#currentNode.plan do newPlan[i] = currentNode.plan[i] end
                table.insert(newPlan, actions)
                local g2 = currentNode.g + (actions.cost or 1)
                local h2 = local_heuristic(newState, goalState)
                if not closedSet[local_stateHash(newState)] then
                    table.insert(openSet, {state = newState, g = g2, h = h2, plan = newPlan})
                end
            end
        end

        ::continue::
    end

    return nil

end

function PZNS_GOAPPlanner.planForNPC(npcSurvivor, goalState, actions)
    if not npcSurvivor then
        return nil
    end

    local worldState = PZNS_GOAPWorldState.getWorldStateForNPC(npcSurvivor)
    return PZNS_GOAPPlanner.plan(worldState, goalState, actions)
end

return PZNS_GOAPPlanner;
