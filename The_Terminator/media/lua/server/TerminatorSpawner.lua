

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
    
    return character
end

local function OnServerStarted()
    print("[Spawner] Server started, spawning Terminator NPC...")
    Terminator(100, 100, 0, {
        name = "Terminator",
        username = "terminator_npc",
        initialGoals = { ELIMINATE_PLAYER = 10 },
        clothing = { "Base.ShirtOrange", "Base.Jeans" }
    })
end

Events.OnServerStarted.Add(OnServerStarted)
