local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WalkToSquareXYZ = require("05_npc_actions/PZNS_WalkTo").PZNS_WalkToSquareXYZ
local Planner = require("07_npc_ai/PZNS_GOAP_Planner") -- Your planner
-- PZNS action modules (wrapped by GOAP actions below)
local PZNS_GatherWeapon = require("05_npc_actions/PZNS_GatherWeapon")
local PZNS_HuntPlayer = require("05_npc_actions/PZNS_HuntPlayer")
local PZNS_StalkPlayer = require("05_npc_actions/PZNS_StalkPlayer")

local GOAPTerminatorBrain = {}

-- GOAP Actions using PZNS movement/combat
local MoveToPlayerAction = {
    name = "MoveToPlayer",
    cost = 1,
    preconditions = { playerSeen = true },
    effects = { atPlayer = true },
    perform = function(action, npcSurvivor, worldState)
        if not worldState.playerPosition then return false end
        
        -- Use PZNS's movement system
        PZNS_WalkToSquareXYZ(
            npcSurvivor,
            worldState.playerPosition.x,
            worldState.playerPosition.y,
            worldState.playerPosition.z
        )
        return true
    end
}

-- How many ticks to wait between planner invocations per NPC (reduce CPU and avoid double-planning)
local PLAN_COOLDOWN_TICKS = 10

    -- Additional GOAP actions (wrappers around PZNS actions)
    local GatherWeaponAction = {
        name = "GatherWeapon",
        cost = 1,
        preconditions = { hasWeapon = false },
        effects = { hasWeapon = true },
        perform = function(action, npcSurvivor, worldState)
            if not PZNS_GatherWeapon or not PZNS_GatherWeapon.PZNS_GatherWeapon then return false end
            local ok, res = pcall(function()
                return PZNS_GatherWeapon.PZNS_GatherWeapon(npcSurvivor, nil)
            end)
            return ok and res ~= false
        end
    }

    local ReloadWeaponAction = {
        name = "ReloadWeapon",
        cost = 1,
        preconditions = { hasWeapon = true },
        effects = { weaponLoaded = true },
        perform = function(action, npcSurvivor, worldState)
            if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_SetLoadedGun then
                pcall(function() PZNS_UtilsNPCs.PZNS_SetLoadedGun(npcSurvivor) end)
                return true
            end
            return false
        end
    }

    local UseMeleeWeaponAction = {
        name = "UseMelee",
        cost = 1,
        preconditions = { hasWeapon = true },
        effects = { atPlayer = true },
        perform = function(action, npcSurvivor, worldState)
            if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_EquipLastWeaponNPCSurvivor then
                pcall(function() PZNS_UtilsNPCs.PZNS_EquipLastWeaponNPCSurvivor(npcSurvivor) end)
            end
            return true
        end
    }

    local FleeAction = {
        name = "Flee",
        cost = 3,
        preconditions = {},
        effects = { safe = true },
        perform = function(action, npcSurvivor, worldState)
            local npcIso = npcSurvivor.npcIsoPlayerObject
            local player = getPlayer()
            if not npcIso or not player then return false end
            local nx, ny, nz = npcIso:getX(), npcIso:getY(), npcIso:getZ()
            local px, py = player:getX(), player:getY()
            local dx, dy = nx - px, ny - py
            local mag = math.max(0.1, math.sqrt(dx*dx + dy*dy))
            local tx = math.floor(nx + (dx / mag) * 6)
            local ty = math.floor(ny + (dy / mag) * 6)
            pcall(function() PZNS_WalkToSquareXYZ(npcSurvivor, tx, ty, nz) end)
            return true
        end
    }

    local SearchForAmmoAction = {
        name = "SearchAmmo",
        cost = 2,
        preconditions = { hasWeapon = true },
        effects = { weaponLoaded = true },
        perform = function(action, npcSurvivor, worldState)
            if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_SetLoadedGun then
                pcall(function() PZNS_UtilsNPCs.PZNS_SetLoadedGun(npcSurvivor) end)
                return true
            end
            return false
        end
    }

    local HuntPlayerAction = {
        name = "HuntPlayer",
        cost = 1,
        preconditions = { playerSeen = true },
        effects = { atPlayer = true },
        perform = function(action, npcSurvivor, worldState)
            if not PZNS_HuntPlayer or not PZNS_HuntPlayer.PZNS_HuntPlayer then return false end
            local ok, res = pcall(function()
                return PZNS_HuntPlayer.PZNS_HuntPlayer(npcSurvivor, getPlayer())
            end)
            return ok and res ~= false
        end
    }

local AttackPlayerAction = {
    name = "AttackPlayer",
    cost = 2,
    preconditions = { atPlayer = true, hasWeapon = true },
    effects = { playerEliminated = true },
    perform = function(action, npcSurvivor, worldState)
        -- Use PZNS's combat system
        local player = getPlayer()
        if player then
            -- Clear any pending non-combat actions so NPC can engage
            if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions then
                PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor)
            end
            npcSurvivor.aimTarget = player
            npcSurvivor.canAttack = true
            -- Mark job as Terminator to indicate active pursuit
            npcSurvivor.jobName = "Terminator"
            -- PZNS AI will handle actual attack execution
            return true
        end
        return false
    end
}

-- Sense the world (replace PZNS job logic)
function GOAPTerminatorBrain.sense(npcSurvivor)
    local worldState = {
        playerSeen = false,
        atPlayer = false,
        hasWeapon = false,
        playerPosition = nil
    }
    
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    if not npcIsoPlayer then return worldState end
    
    local player = getPlayer()
    if player then
        local px, py = player:getX(), player:getY()
        local nx, ny = npcIsoPlayer:getX(), npcIsoPlayer:getY()
        local dx, dy = px - nx, py - ny
        local dist2 = dx*dx + dy*dy
        
        if dist2 <= 400 then -- ~20 tiles
            worldState.playerSeen = true
            worldState.playerPosition = { x = px, y = py, z = player:getZ() }
        end
        
        if dist2 <= 4 then -- close range
            worldState.atPlayer = true
        end
    end
    
    -- Check if NPC has weapon equipped
    local weapon = npcIsoPlayer:getPrimaryHandItem()
    worldState.hasWeapon = (weapon ~= nil and weapon:IsWeapon())
    
    return worldState
end

-- Run GOAP planning and execute
function GOAPTerminatorBrain.tick(npcSurvivor)
    if not npcSurvivor then return end

    -- Ensure the NPC's square is loaded and the IsoPlayer exists
    if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_GetIsNPCSquareLoaded and not PZNS_UtilsNPCs.PZNS_GetIsNPCSquareLoaded(npcSurvivor) then
        return
    end

    -- Make sure Terminators are marked with a job so PZNS systems treat them as an AI-controlled unit
    if npcSurvivor.jobName ~= "Terminator" then
        npcSurvivor.jobName = "Terminator"
    end

    -- Keep Terminator alive and reset debuffs (optional invulnerability support)
    if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_EnsureNPCAlive then
        PZNS_UtilsNPCs.PZNS_EnsureNPCAlive(npcSurvivor)
    end

    -- Debug: indicate tick
    -- print("[PZNS_GOAPTerminatorBrain] tick for ", tostring(npcSurvivor.survivorID))

    -- Sense current world state
    local worldState = GOAPTerminatorBrain.sense(npcSurvivor)
    
    -- Define goal
    local goal = { playerEliminated = true }
    
    -- Available actions
    local actions = {
        MoveToPlayerAction,
        AttackPlayerAction,
        GatherWeaponAction,
        ReloadWeaponAction,
        UseMeleeWeaponAction,
        FleeAction,
        SearchForAmmoAction,
        HuntPlayerAction
    }
    
    -- Decrement per-NPC plan cooldown
    if not npcSurvivor.goapPlanCooldown then npcSurvivor.goapPlanCooldown = 0 end
    if npcSurvivor.goapPlanCooldown > 0 then npcSurvivor.goapPlanCooldown = npcSurvivor.goapPlanCooldown - 1 end

    -- Get or create plan. If Planner.goap_plan is missing, use a small fallback to avoid crashes.
    if not npcSurvivor.goapPlan or #npcSurvivor.goapPlan == 0 then
        -- Only invoke the planner if cooldown expired to avoid running it every tick
        if npcSurvivor.goapPlanCooldown <= 0 then
            -- Avoid evaluating Planner.goap_plan when Planner is nil (Kahlua may try to index during evaluation)
            if Planner ~= nil then
                if type(Planner.goap_plan) == "function" then
                    print("[PZNS_GOAPTerminatorBrain] Invoking planner for ", tostring(npcSurvivor.survivorID))
                    local ok, planOrErr = pcall(function()
                        return Planner.goap_plan(worldState, actions, goal, { verbose = false })
                    end)
                    if ok and planOrErr then
                        npcSurvivor.goapPlan = planOrErr
                        npcSurvivor.goapPlanCooldown = PLAN_COOLDOWN_TICKS
                    else
                        print("[PZNS_GOAPTerminatorBrain] Planner.goap_plan call failed: ", tostring(planOrErr))
                        npcSurvivor.goapPlan = {}
                        -- small cooldown to avoid spamming failures
                        npcSurvivor.goapPlanCooldown = math.max(2, math.floor(PLAN_COOLDOWN_TICKS / 4))
                    end
                else
                    print("[PZNS_GOAPTerminatorBrain] Planner.goap_plan is not a function; using fallback plan")
                    if worldState and worldState.playerSeen then
                        npcSurvivor.goapPlan = { MoveToPlayerAction }
                    else
                        npcSurvivor.goapPlan = {}
                    end
                    npcSurvivor.goapPlanCooldown = PLAN_COOLDOWN_TICKS
                end
            else
                print("[PZNS_GOAPTerminatorBrain] Planner is nil; using fallback plan")
                if worldState and worldState.playerSeen then
                    npcSurvivor.goapPlan = { MoveToPlayerAction }
                else
                    npcSurvivor.goapPlan = {}
                end
                npcSurvivor.goapPlanCooldown = PLAN_COOLDOWN_TICKS
            end
        end
    end
    
    -- Execute next action
    if npcSurvivor.goapPlan and #npcSurvivor.goapPlan > 0 then
        local nextAction = npcSurvivor.goapPlan[1]
        local success = false
        local ok, err = pcall(function()
            success = nextAction.perform(nextAction, npcSurvivor, worldState)
        end)
        if not ok then
            print("[PZNS_GOAPTerminatorBrain] action perform error: ", tostring(err))
            npcSurvivor.goapPlan = nil
            return
        end
        
        if success then
            table.remove(npcSurvivor.goapPlan, 1)
        else
            -- Replan on failure
            npcSurvivor.goapPlan = nil
        end
    end
end

return GOAPTerminatorBrain