

TerminatorAgent = require "server.TerminatorAgent"


local TerminatorSpawner = {}

-- Internal helper: get or create the Terminator ModData table
-- Pattern from: PZNS_Framework/media/lua/client/02_mod_utils/PZNS_UtilsDataNPCs.lua:PZNS_GetCreateActiveNPCsModData()
local function getTerminatorModData()
    local modData = ModData.getOrCreate("TerminatorAgents")
    modData.agents = modData.agents or {}
    modData.nextID = modData.nextID or 1000
    return modData
end

-- Internal helper: create an IsoPlayer object with proper PZ API calls
-- Pattern from: PZNS_Framework/media/lua/client/04_data_management/PZNS_NPCsManager.lua:createIsoPlayer()
local function createIsoPlayer(x, y, z, isFemale, forename, surname, agentID)
    local cell = getWorld():getCell()
    local square = cell:getGridSquare(x, y, z)
    
    if not square then
        print(string.format("[Spawner] ERROR: Invalid grid square at %d, %d, %d", x, y, z))
        return nil
    end
    
    -- Ensure NPC spawns on solid ground (like PZNS does in createIsoPlayer)
    local spawnZ = 0
    if square:isSolidFloor() then
        spawnZ = square:getZ()
    end
    
    -- Defensive checks: Some Java classes may be unavailable in certain contexts
    if SurvivorFactory == nil then
        print("[Spawner] ERROR: SurvivorFactory is nil in this environment; cannot create IsoPlayer")
        return nil
    end
    if IsoPlayer == nil then
        print("[Spawner] ERROR: IsoPlayer class is not available in this environment; cannot create IsoPlayer")
        return nil
    end

    -- Create survivor description (appearance, gender, name)
    -- Uses SurvivorFactory.CreateSurvivor like PZNS does
    local ok, survivorDesc = pcall(function()
        return SurvivorFactory.CreateSurvivor(nil, isFemale)
    end)
    if not ok or not survivorDesc then
        print("[Spawner] ERROR: SurvivorFactory.CreateSurvivor failed or returned nil")
        return nil
    end
    survivorDesc:setForename(forename)
    survivorDesc:setSurname(surname)

    -- Create the IsoPlayer object in the world
    -- Pattern: IsoPlayer.new(getWorld():getCell(), survivorDesc, x, y, z)
    local success, isoPlayer = pcall(function()
        return IsoPlayer.new(
            cell,
            survivorDesc,
            square:getX(),
            square:getY(),
            spawnZ
        )
    end)
    if not success or not isoPlayer then
        print(string.format("[Spawner] ERROR: IsoPlayer.new failed to create player at %d,%d,%d", x, y, z))
        return nil
    end
    
    -- Mark as NPC and store agent ID in ModData
    -- Pattern from PZNS: isoPlayer:setNPC(true)
    isoPlayer:setNPC(true)
    isoPlayer:setSceneCulled(false)
    isoPlayer:getModData().agentID = agentID
    isoPlayer:getModData().isTerminator = true
    
    return isoPlayer
end

-- Create a new Terminator agent and spawn it into the world
-- Returns the created agent instance
function TerminatorSpawner.spawnTerminator(x, y, z, templateConfig)
    local modData = getTerminatorModData()
    local agentID = "Terminator_" .. modData.nextID
    modData.nextID = modData.nextID + 1
    
    print(string.format("[Spawner] Creating Terminator agent '%s' at %d,%d,%d", agentID, x, y, z))
    
    -- Create the IsoPlayer in the world (persistent across saves)
    local isoPlayer = createIsoPlayer(
        x, y, z,
        templateConfig.isFemale or false,
        templateConfig.forename or "The",
        templateConfig.surname or "Terminator",
        agentID
    )
    
    if not isoPlayer then
        print("[Spawner] ERROR: Failed to create IsoPlayer")
        return nil
    end
    
    -- Create the Terminator agent instance
    local agent = TerminatorAgent.new(isoPlayer)
    agent.agentID = agentID
    agent.template = templateConfig
    agent.isAlive = true
    agent.isSpawned = true
    
    -- Store initial position for persistence
    agent.savedX = x
    agent.savedY = y
    agent.savedZ = z
    
    -- Build navigation graph for pathfinding
    print("[Spawner] Building navigation graph for agent...")
    agent:buildNavigationGraph()
    
    -- Mark as ready for action execution
    agent.spawned = true
    
    -- Persist agent to ModData (survives save/load like PZNS does)
    modData.agents[agentID] = agent
    
    print(string.format("[Spawner] Agent '%s' spawned successfully", agentID))
    return agent, agentID
end

-- Reload all Terminator agents from ModData after game load
-- Pattern from: PZNS_Framework/media/lua/client/02_mod_utils/PZNS_UtilsDataNPCs.lua:PZNS_InitLoadNPCsData()
function TerminatorSpawner.loadAgentsFromSave()
    local modData = getTerminatorModData()
    
    -- Defensive check: no ModData
    if not modData then
        print("[Spawner] WARNING: No ModData found, skipping load")
        return
    end
    
    -- Defensive check: no agents table
    if not modData.agents then
        print("[Spawner] No saved agents in ModData, skipping load")
        return
    end
    
    -- Defensive check: agents table is empty
    --[[if next(modData.agents) == nil then
        print("[Spawner] Agents table is empty, skipping load")
        return
    end]]
    
    print("[Spawner] Loading Terminator agents from save...")
    local loadedCount = 0
    local errorCount = 0
    
    for agentID, savedAgent in pairs(modData.agents) do
        local shouldSkip = false
        
        -- Defensive check: savedAgent is nil
        if not savedAgent then
            print(string.format("[Spawner] WARNING: Agent '%s' is nil, skipping", agentID))
            errorCount = errorCount + 1
            shouldSkip = true
        end
        
        -- Defensive check: agent is dead
        if not shouldSkip and not savedAgent.isAlive then
            print(string.format("[Spawner] Agent '%s' is dead, skipping", agentID))
            shouldSkip = true
        end
        
        -- Defensive check: saved position data exists
        if not shouldSkip and (not savedAgent.savedX or not savedAgent.savedY or not savedAgent.savedZ) then
            print(string.format("[Spawner] WARNING: Agent '%s' missing position data, skipping", agentID))
            errorCount = errorCount + 1
            shouldSkip = true
        end
        
        -- Defensive check: template exists
        if not shouldSkip and not savedAgent.template then
            print(string.format("[Spawner] WARNING: Agent '%s' missing template, using defaults", agentID))
            savedAgent.template = {
                isFemale = false,
                forename = "The",
                surname = "Terminator"
            }
        end
        
        -- Skip to next agent if flagged
        if shouldSkip then
            -- continue to next iteration
        else
            print(string.format("[Spawner] Restoring agent '%s' from position %d,%d,%d", 
                agentID, savedAgent.savedX, savedAgent.savedY, savedAgent.savedZ))
            
            -- Recreate the IsoPlayer object at the saved location
            local isoPlayer = createIsoPlayer(
                savedAgent.savedX,
                savedAgent.savedY,
                savedAgent.savedZ,
                savedAgent.template.isFemale or false,
                savedAgent.template.forename or "The",
                savedAgent.template.surname or "Terminator",
                agentID
            )
            
            if isoPlayer then
                -- Reconnect IsoPlayer to the saved agent instance
                savedAgent.character = isoPlayer
                savedAgent.spawned = true
                
                -- Restore metatable so agent methods work (metatables are lost during ModData serialization)
                setmetatable(savedAgent, { __index = TerminatorAgent })
                
                -- Safe pcall for buildNavigationGraph in case it fails
                local success, err = pcall(function()
                    savedAgent:buildNavigationGraph()
                end)
                
                if not success then
                    print(string.format("[Spawner] WARNING: Failed to build nav graph for '%s': %s", agentID, err))
                    errorCount = errorCount + 1
                else
                    loadedCount = loadedCount + 1
                    print(string.format("[Spawner] Agent '%s' restored successfully", agentID))
                end
            else
                print(string.format("[Spawner] ERROR: Failed to create IsoPlayer for agent '%s'", agentID))
                errorCount = errorCount + 1
            end
        end
    end
    
    print(string.format("[Spawner] Load complete - Loaded: %d, Errors: %d", loadedCount, errorCount))
end

-- Save all agent state to ModData when game saves
-- Pattern from: PZNS_Framework/media/lua/client/02_mod_utils/PZNS_UtilsDataNPCs.lua:PZNS_SaveNPCData()
function TerminatorSpawner.saveAgents()
    local modData = getTerminatorModData()
    
    for agentID, agent in pairs(modData.agents) do
        if agent and agent.character then
            -- Update position and state before save (like PZNS does)
            agent.savedX = agent.character:getX()
            agent.savedY = agent.character:getY()
            agent.savedZ = agent.character:getZ()
            agent.isAlive = agent.character:isAlive()
            
            -- Note: Full IsoPlayer serialization via isoPlayer:save(fileName)
            -- can be added later if inventory/skills persistence is needed
        end
    end
    
    print("[Spawner] Terminator agents saved to ModData")
end

-- Get an agent by ID
function TerminatorSpawner.getAgent(agentID)
    local modData = getTerminatorModData()
    return modData.agents[agentID]
end

-- Get all agents
function TerminatorSpawner.getAllAgents()
    local modData = getTerminatorModData()
    return modData.agents
end

-- Called when server starts to spawn initial NPCs
local function onServerStarted()
    print("[Spawner] Server started - initializing Terminator agents")
    
    -- Spawn the main Terminator NPC
    TerminatorSpawner.spawnTerminator(100, 100, 0, {
        isFemale = false,
        forename = "The",
        surname = "Terminator",
        initialGoals = { ELIMINATE_PLAYER = 10 }
    })
end

-- Called when game loads to restore agents from save (Events.OnGameStart)
local function onGameStart()
    print("[Spawner] Game started - loading saved Terminator agents")
    TerminatorSpawner.loadAgentsFromSave()
end

-- If no agents were restored (singleplayer/debug), spawn a default Terminator so testing is easier
local function ensureAgentPresentAfterLoad()
    local modData = getTerminatorModData()
    if not modData then return end
    if not modData.agents or next(modData.agents) == nil then
        print("[Spawner] No Terminator agents found after load; scheduling a default agent spawn on next safe tick")
        -- Don't call spawn APIs directly during OnGameStart (they may not be available yet).
        -- Instead, set a pending flag that onTick will perform once when safe.
        TerminatorSpawner._pendingAutoSpawn = true
    end
end

-- Ensure we run the fallback after game start load sequence completes
Events.OnGameStart.Add(ensureAgentPresentAfterLoad)

-- Called when game saves to persist agent state (Events.OnSave)
local function onSave()
    print("[Spawner] Game saving - persisting Terminator agents")
    TerminatorSpawner.saveAgents()
end

-- ============================================================
-- DEBUG SPAWNING
-- ============================================================
-- Spawn Terminator at player location (debug mode)
-- Usage in console: /c TerminatorSpawner.debugSpawnAtPlayer()
function TerminatorSpawner.debugSpawnAtPlayer()
    local player = getPlayer()
    if not player then
        print("[Spawner] ERROR: No player found")
        return
    end
    
    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()
    
    print(string.format("[Spawner DEBUG] Spawning Terminator at player location: %d, %d, %d", x, y, z))
    
    local agent, agentID = TerminatorSpawner.spawnTerminator(x + 5, y + 5, z, {
        isFemale = false,
        forename = "The",
        surname = "Terminator",
        initialGoals = { ELIMINATE_PLAYER = 10 }
    })
    
    if agent then
        print(string.format("[Spawner DEBUG] Terminator spawned successfully with ID: %s", agentID))
    else
        print("[Spawner DEBUG] FAILED to spawn Terminator")
    end
end

-- Spawn Terminator at specific coordinates (debug mode)
-- Usage: /c TerminatorSpawner.debugSpawnAtCoords(100, 100, 0)
function TerminatorSpawner.debugSpawnAtCoords(x, y, z)
    print(string.format("[Spawner DEBUG] Spawning Terminator at coords: %d, %d, %d", x, y, z))
    
    local agent, agentID = TerminatorSpawner.spawnTerminator(x, y, z, {
        isFemale = false,
        forename = "The",
        surname = "Terminator",
        initialGoals = { ELIMINATE_PLAYER = 10 }
    })
    
    if agent then
        print(string.format("[Spawner DEBUG] Terminator spawned with ID: %s", agentID))
    else
        print("[Spawner DEBUG] FAILED to spawn Terminator")
    end
end

-- List all active agents (debug mode)
-- Usage: /c TerminatorSpawner.debugListAgents()
function TerminatorSpawner.debugListAgents()
    local agents = TerminatorSpawner.getAllAgents()
    print("[Spawner DEBUG] Active Terminator Agents:")
    if not agents or next(agents) == nil then
        print("  (none)")
        return
    end
    for agentID, agent in pairs(agents) do
        local status = agent.isAlive and "ALIVE" or "DEAD"
        local pos = string.format("%d, %d, %d", agent.savedX or 0, agent.savedY or 0, agent.savedZ or 0)
        print(string.format("  %s [%s] at %s", agentID, status, pos))
    end
end

-- Kill all agents (debug mode)
-- Usage: /c TerminatorSpawner.debugKillAll()
function TerminatorSpawner.debugKillAll()
    local agents = TerminatorSpawner.getAllAgents()
    print("[Spawner DEBUG] Killing all Terminator agents...")
    for agentID, agent in pairs(agents) do
        if agent.character then
            agent.character:setHealth(0)
            print(string.format("  Killed: %s", agentID))
        end
    end
end

-- Register event hooks
Events.OnServerStarted.Add(onServerStarted)
Events.OnGameStart.Add(onGameStart)
Events.OnSave.Add(onSave)

-- Lightweight tick driver: call agent:tick() periodically
local tickCounter = 0
local TICK_INTERVAL = 10 -- run agent logic every 10 ticks to reduce overhead
local function onTick()
    tickCounter = tickCounter + 1
    if tickCounter % TICK_INTERVAL ~= 0 then return end

    -- If an auto-spawn was requested during OnGameStart, perform it now in a safe context
    if TerminatorSpawner._pendingAutoSpawn then
        TerminatorSpawner._pendingAutoSpawn = nil
        print("[Spawner] Performing scheduled auto-spawn now (safe tick)")
        local ok, err = pcall(function()
            if TerminatorSpawner and type(TerminatorSpawner.spawnTerminator) == "function" then
                TerminatorSpawner.spawnTerminator(100, 100, 0, {
                    isFemale = false,
                    forename = "The",
                    surname = "Terminator",
                    initialGoals = { ELIMINATE_PLAYER = 10 }
                })
            else
                print("[Spawner] WARNING: spawn function not available during scheduled auto-spawn")
            end
        end)
        if not ok then
            print(string.format("[Spawner] ERROR: scheduled auto-spawn failed: %s", tostring(err)))
        end
    end

    local modData = getTerminatorModData()
    if not modData or not modData.agents then return end

    for agentID, agent in pairs(modData.agents) do
        if agent and agent.isAlive and agent.spawned and agent.tick then
            -- protect each agent tick with pcall to avoid one broken agent stopping the loop
            local ok, err = pcall(function()
                agent:tick()
            end)
            if not ok then
                print(string.format("[Spawner] ERROR: Agent '%s' tick failed: %s", agentID, tostring(err)))
            end
        end
    end
end
Events.OnTick.Add(onTick)

-- Expose to global for debug console access (so `/c TerminatorSpawner.debugSpawnAtPlayer()` works)
_G.TerminatorSpawner = TerminatorSpawner

return TerminatorSpawner
