local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_WalkToSquareXYZ = require("05_npc_actions/PZNS_WalkTo").PZNS_WalkToSquareXYZ
local Planner = require("07_npc_ai/PZNS_GOAP_Planner") -- Your planner
-- PZNS action modules (wrapped by GOAP actions below)
local PZNS_GatherWeapon = require("05_npc_actions/PZNS_GatherWeapon")
local PZNS_HuntPlayer = require("05_npc_actions/PZNS_HuntPlayer")
local PZNS_StalkPlayer = require("05_npc_actions/PZNS_StalkPlayer")
local PZNS_WeaponAiming = require("05_npc_actions/PZNS_WeaponAiming")
local PZNS_WeaponAttack = require("05_npc_actions/PZNS_WeaponAttack")
local PZNS_WeaponReload = require("05_npc_actions/PZNS_WeaponReload")

-- Toggle this to false to disable GOAPTerminator behavior for testing (can be set at runtime)
PZNS_GOAP_ENABLED = PZNS_GOAP_ENABLED == nil and true or PZNS_GOAP_ENABLED

local GOAPTerminatorBrain = {}

-- GOAP Actions using PZNS movement/combat
local MoveToPlayerAction = {
    name = "MoveToPlayer",
    cost = 1,
    preconditions = { playerSeen = true },
    effects = { atPlayer = true },
    perform = function(action, npcSurvivor, worldState)
        -- If we're already at the player, consider this action complete so the next action can run.
        if worldState.atPlayer then
            return true
        end

        if not worldState.playerPosition then return false end

        -- Use PZNS's movement system to queue a walk action towards the player's current position.
        -- We return false here so the MoveToPlayerAction remains the current plan step until the NPC
        -- actually reaches the player (worldState.atPlayer becomes true). This prevents GOAP from
        -- consuming the movement step immediately and re-invoking the planner each tick.
        local _ = PZNS_WalkToSquareXYZ(
            npcSurvivor,
            worldState.playerPosition.x,
            worldState.playerPosition.y,
            worldState.playerPosition.z
        )
        return false
    end
}

-- How many ticks to wait between planner invocations per NPC (reduce CPU and avoid double-planning)
-- Increased cooldown to avoid frequent replanning. Adjust if you want more responsive replans.
local PLAN_COOLDOWN_TICKS = 120

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
            -- Prefer the full reload routine which uses timed actions and inventory checks
            if PZNS_WeaponReload then
                pcall(function() PZNS_WeaponReload(npcSurvivor) end)
                return true
            end
            -- Fallback to a light helper if present
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

    -- Aim weapon action: try to set NPC into aiming state; keep action active until aimed or target lost
    local AimWeaponAction = {
        name = "AimWeapon",
        cost = 1,
        preconditions = { hasWeapon = true, playerSeen = true, inAimRange = true },
        effects = { aimed = true },
        perform = function(action, npcSurvivor, worldState)
            print("[GOAP_AimWeapon] perform called for " .. tostring(npcSurvivor and npcSurvivor.survivorID))
            if not PZNS_WeaponAiming then return false end
            -- Ensure aimTarget is set
            if worldState.playerPosition then
                npcSurvivor.aimTarget = getPlayer()
            end
            pcall(function() PZNS_WeaponAiming(npcSurvivor) end)
            local npcIso = npcSurvivor.npcIsoPlayerObject
            if npcIso and npcIso:NPCGetAiming() == true then
                print("[GOAP_AimWeapon] NPC is aiming")
                return true
            end
            print("[GOAP_AimWeapon] NPC not yet aiming")
            return false
        end
    }

    -- Attack action: invoke weapon attack repeatedly until target is dead or out of sight
    local AttackWeaponAction = {
        name = "AttackWeapon",
        cost = 1,
        preconditions = { aimed = true, hasWeapon = true, inAimRange = true },
        effects = { playerEliminated = true },
        perform = function(action, npcSurvivor, worldState)
            print("[GOAP_AttackWeapon] perform called for " .. tostring(npcSurvivor and npcSurvivor.survivorID))
            -- Ensure we have a target
            if not worldState.playerPosition then return true end -- nothing to do, let planner re-evaluate
            npcSurvivor.aimTarget = getPlayer()
            npcSurvivor.canAttack = true
            -- Run aiming/attack routines; these rely on timed ticks internally
            pcall(function() PZNS_WeaponAiming(npcSurvivor) end)
            pcall(function() PZNS_WeaponAttack(npcSurvivor) end)
            -- If the player is dead or not visible, consider action complete so planner can move on
            local player = getPlayer()
            if not player or not player:isAlive() then
                return true
            end
            local nx, ny = npcSurvivor.npcIsoPlayerObject:getX(), npcSurvivor.npcIsoPlayerObject:getY()
            local px, py = player:getX(), player:getY()
            local dx, dy = px - nx, py - ny
            local dist2 = dx*dx + dy*dy
            if dist2 > (30*30) then -- lost sight / too far
                print("[GOAP_AttackWeapon] target out of range, dist2=" .. tostring(dist2))
                return true
            end
            -- Keep this action active while attacking
            return false
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

        -- If we have a weapon, expose whether the player is within aiming range (squared distance compare)
        local weapon = npcIsoPlayer:getPrimaryHandItem()
        if weapon and weapon:IsWeapon() then
            local range = weapon:getMaxRange() or 2
            worldState.inAimRange = (dist2 <= (range * range))
        else
            worldState.inAimRange = false
        end
    end
    
    -- Check if NPC has weapon equipped
    local weapon = npcIsoPlayer:getPrimaryHandItem()
    worldState.hasWeapon = (weapon ~= nil and weapon:IsWeapon())
    
    return worldState
end

-- Run GOAP planning and execute
function GOAPTerminatorBrain.tick(npcSurvivor)
    -- Quick toggle to disable GOAP processing for debugging other NPC logic
    if not PZNS_GOAP_ENABLED then
        return
    end

    if not npcSurvivor then return end

    -- Only run GOAP for NPCs explicitly marked as Terminators.
    -- This is defensive: prevents accidental invocation from affecting all NPCs.
    if not npcSurvivor.isTerminator then
        return
    end

    -- Ensure the NPC's square is loaded and the IsoPlayer exists
    if PZNS_UtilsNPCs and PZNS_UtilsNPCs.PZNS_GetIsNPCSquareLoaded and not PZNS_UtilsNPCs.PZNS_GetIsNPCSquareLoaded(npcSurvivor) then
        return
    end

    -- Make sure Terminators are marked with a job so PZNS systems treat them as an AI-controlled unit
    if npcSurvivor.isTerminator and npcSurvivor.jobName ~= "Terminator" then
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
        AimWeaponAction,
        AttackWeaponAction,
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
    -- If we don't currently have a plan and the player isn't visible, skip planning (saves CPU)
    if (not npcSurvivor.goapPlan or #npcSurvivor.goapPlan == 0) and not worldState.playerSeen then
        return
    end

    -- Get or create plan. If Planner.goap_plan is missing, use a small fallback to avoid crashes.
    if not npcSurvivor.goapPlan or #npcSurvivor.goapPlan == 0 then
        -- Only invoke the planner if cooldown expired to avoid running it every tick
        if npcSurvivor.goapPlanCooldown <= 0 then
            -- Avoid evaluating Planner.goap_plan when Planner is nil (Kahlua may try to index during evaluation)
            if Planner ~= nil then
                if type(Planner.goap_plan) == "function" then
                    print("[PZNS_GOAPTerminatorBrain] Invoking planner for ", tostring(npcSurvivor.survivorID))
                    -- Ask planner to limit expansions to avoid runaway searches in complex states
                    local ok, planOrErr = pcall(function()
                        return Planner.goap_plan(worldState, actions, goal, { verbose = false, maxExpansions = 1000 })
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