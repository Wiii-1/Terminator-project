local Planner = require("TerminatorPlanner")
local TerminatorAgent = require("server.TerminatorAgent")
local WorldState = require("shared.WorldState")

GLOBAL_TERMINATOR_NPCS = GLOBAL_TERMINATOR_NPCS or {}

--  spawn IsoSurvivor at (x,y,z)
local function spawnIsoSurvivor(x, y, z)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then 
        print("[Spawn] Failed: no grid square at " .. x .. "," .. y .. "," .. z)
        return nil 
    end

    local isoSurvivor = IsoSurvivor.new(sq, "BaseMale")
    isoSurvivor:setX(x + 0.5)
    isoSurvivor:setY(y + 0.5)
    isoSurvivor:setZ(z)
    isoSurvivor:setName("Terminator")
    isoSurvivor:setCanWalkThrough(true) -- Prevent collision issues
    isoSurvivor:setBlockMovement(false)

    getCell():addObjectToProcess(isoSurvivor) -- Properly add to game world
    return isoSurvivor
end


local function SpawnTerminatorAgent(x, y, z)
    local npc = Planner.deepcopy(TerminatorAgent)
    npc.state.x = math.floor(x)
    npc.state.y = math.floor(y)
    npc.state.z = z or 0

    local entity = spawnIsoSurvivor(npc.state.x, npc.state.y, npc.state.z)
    if entity then
        npc.entity = entity
        table.insert(GLOBAL_TERMINATOR_NPCS, npc)
        print("[Spawn] Terminator NPC spawned at:", npc.state.x, npc.state.y, npc.state.z)
        return npc
    else
        print("[Spawn] Failed to spawn Terminator NPC")
        return nil
    end
end

local function AutoSpawnTerminator()
    local player = getOnlinePlayers()[1] or getSpecificPlayer(0)
    if not player then return end

    SpawnTerminatorAgent(player:getX(), player:getY(), player:getZ())
end

function SpawnTerminatorAt(x, y, z)
    SpawnTerminatorAgent(x, y, z or 0)
end

Events.OnKeyPressed.Add(function(key)
    if key == 25 then -- P key
        local player = getSpecificPlayer(0)
        if player then
            SpawnTerminatorAt(player:getX(), player:getY(), player:getZ())
        end
    end
end)

local function UpdateAllTerminators()
    print("[DEBUG] UpdateAllTerminators called")
    for _, npc in ipairs(GLOBAL_TERMINATOR_NPCS) do
        npc:executePlan(WorldState)

        -- Sync physical entity location with AI state
        if npc.entity then
            npc.entity:setX(npc.state.x + 0.5)
            npc.entity:setY(npc.state.y + 0.5)
            npc.entity:setZ(npc.state.z or 0)
        end
    end
end

Events.OnGameStart.Add(function()
    print("[Terminator] Mod initialized")
    AutoSpawnTerminator() -- Optional: auto-spawn on game start
end)


Events.OnTick.Add(UpdateAllTerminators)
