

local TerminatorAgent = require("server.TerminatorAgent")

local function Terminator(x, y, z, npcTemplate)
    print("[Spawner] Spawning Terminator NPC at", x, y, z)

    local character = addHumanoidCharacter(x, y, z)
    
    if not character then
        print("[ERROR] Failed to spawn NPC at", x, y, z)
        return nil
    end
    
    character:setFullName(npcTemplate.name)
    character:setUsername(npcTemplate.username or npcTemplate.name)
    
    local zombie = character:getZombieDescription()
    zombie:setClothingItem(npcTemplate.clothing)
    
    ModData = ModData or {}
    
    local npcID = character:getID()
    ModData.NPCs = ModData.NPCs or {}
    ModData.NPCs[npcID] = {
        name = npcTemplate.name,
        initialGoals = npcTemplate.initialGoals,
        worldState = {},
        actionPlan = {}
    }

    -- create an agent instance and initialize it before allowing movement
    local agent = TerminatorAgent.new(character)
    -- attach the NPC id and template info
    agent.npcID = npcID
    agent.template = npcTemplate
    -- build the navigation graph synchronously so the agent is ready to path
    -- this can be slow on large maps; adjust build dimensions inside the method if needed
    agent:buildNavigationGraph()
    agent.spawned = true
    -- store agent for later use
    ModData.NPCs[npcID].agent = agent
    
    return character
end

local function OnServerStarted()
    print("[DEBUG] Server started - spawning NPC")
    Terminator(100, 100, 0, {
        name = "Terminator",
        username = "terminator_npc",
        initialGoals = { ELIMINATE_PLAYER = 10 },
        clothing = { "Base.ShirtOrange", "Base.Jeans" }
    })
    print("[DEBUG] NPC spawn attempted")
end

Events.OnServerStarted.Add(OnServerStarted)
