# Terminator NPC Spawning & Persistence Guide

## Overview
The refactored spawner uses patterns from **PZNS_Framework** to ensure proper NPC spawning and persistence across save/load cycles.

---

## Files Modified & Why

### 1. `media/lua/server/TerminatorSpawner.lua` (COMPLETELY REFACTORED)
**Previous Issues:**
- Used `addHumanoidCharacter()` which doesn't properly integrate with PZ's persistence system
- No ModData-based persistence layer
- Missing OnGameStart/OnSave event hooks
- No rebuild logic for loading saved agents

**New Approach (PZNS-inspired):**
- ✅ Uses `IsoPlayer.new()` with proper `SurvivorFactory.CreateSurvivor()` (like PZNS does)
- ✅ Stores agents in `ModData.getOrCreate("TerminatorAgents")` (like PZNS stores in ModData)
- ✅ Hooks `Events.OnGameStart`, `Events.OnSave` for load/persist (like PZNS does)
- ✅ Rebuilds IsoPlayer references on game load from saved ModData

**Key Functions:**
- `TerminatorSpawner.spawnTerminator(x, y, z, config)` - Create & spawn a new Terminator
- `TerminatorSpawner.loadAgentsFromSave()` - Called on game load; rebuilds agents
- `TerminatorSpawner.saveAgents()` - Called on game save; updates ModData
- `TerminatorSpawner.getAgent(agentID)` - Retrieve agent by ID
- `TerminatorSpawner.getAllAgents()` - Get all active agents

### 2. `media/lua/server/TerminatorAgent.lua` (REQUIRE PATHS FIXED)
**Previous Issues:**
- Require paths were missing namespace prefixes (e.g., `require"TerminatorPlanner"` instead of `require"server.TerminatorPlanner"`)
- Led to "require failed" warnings in the game log

**Fixed Paths:**
```lua
-- BEFORE (broken):
local Planner = require"TerminatorPlanner"
local WorldState = require"WorldState"

-- AFTER (correct):
local Planner = require"server.TerminatorPlanner"
local WorldState = require"shared.WorldState"
```

---

## PZNS_Framework Reference Points

### Spawning Pattern
**Location:** `PZNS_Framework/media/lua/client/04_data_management/PZNS_NPCsManager.lua`

**How PZNS creates NPCs:**
```lua
-- PZNS does this:
local survivorDesc = SurvivorFactory.CreateSurvivor(nil, isFemale)
survivorDesc:setForename(forename)
survivorDesc:setSurname(surname)

local isoPlayer = IsoPlayer.new(
    getWorld():getCell(),
    survivorDesc,
    square:getX(),
    square:getY(),
    spawnZ
)
isoPlayer:setNPC(true)
```

**Terminator now does the same** in `createIsoPlayer()` function.

### Persistence Pattern
**Location:** `PZNS_Framework/media/lua/client/02_mod_utils/PZNS_UtilsDataNPCs.lua`

**How PZNS persists NPCs:**
```lua
-- PZNS does this:
local PZNS_ActiveNPCs = ModData.getOrCreate("PZNS_ActiveNPCs")
PZNS_ActiveNPCs[survivorID] = npcSurvivor  -- Save agent state

-- On load:
function PZNS_InitLoadNPCsData()
    for npcID, npcSurvivor in pairs(PZNS_ActiveNPCs) do
        if npcSurvivor.npcIsoPlayerObject == nil then
            PZNS_SpawnNPCFromModData(npcSurvivor)
        end
    end
end
```

**Terminator now does the same:**
- `getTerminatorModData()` → `ModData.getOrCreate("TerminatorAgents")`
- `loadAgentsFromSave()` → Recreates IsoPlayer objects from ModData
- Event hooks → `Events.OnGameStart`, `Events.OnSave`

---

## Spawn Flow Diagram

```
Game Start
   ↓
Events.OnServerStarted fires
   ↓
TerminatorSpawner.spawnTerminator() called
   ├─ createIsoPlayer() → Creates IsoPlayer in world (visible)
   ├─ TerminatorAgent.new() → Creates agent instance
   ├─ agent:buildNavigationGraph() → Pathfinding ready
   ├─ agent.spawned = true → Ready for actions
   └─ ModData.TerminatorAgents[agentID] = agent → Persistent
   ↓
Agent now active in game


Player loads saved game
   ↓
Events.OnGameStart fires
   ↓
TerminatorSpawner.loadAgentsFromSave() called
   ├─ For each saved agent in ModData:
   │  ├─ createIsoPlayer() → Recreate in world at saved position
   │  ├─ Reattach to agent instance
   │  └─ Rebuild nav graph
   └─ Agent restored and active


Player saves game
   ↓
Events.OnSave fires
   ↓
TerminatorSpawner.saveAgents() called
   ├─ For each agent:
   │  ├─ Update savedX, savedY, savedZ from current position
   │  ├─ Update isAlive flag
   │  └─ ModData auto-persists (built-in PZ behavior)
   ↓
Save complete; all agents preserved
```

---

## Persistence Details

### What Gets Saved
- **Agent state** (health, location, current goal, plan)
- **Template config** (name, appearance, initial goals)
- **Serializable data** in `agent` table (anything not a C++ object)

### What Does NOT Get Saved (and why)
- **IsoPlayer object** - C++ objects can't be serialized to ModData
  - **Solution**: Stored IsoPlayer reference is cleared on save; rebuilt on load
- **Navigation graph** - Can be rebuilt in ~1 second on load
  - **Future optimization**: Cache the graph structure separately if needed

### How Persistence Works
1. **OnSave event** → `TerminatorSpawner.saveAgents()` updates positions/state in ModData
2. **Game saves** → ModData is auto-serialized by PZ engine
3. **Player loads save** → ModData is auto-deserialized by PZ engine
4. **OnGameStart event** → `TerminatorSpawner.loadAgentsFromSave()` rebuilds agents

This matches **PZNS_Framework's approach exactly**.

---

## Spawn Configuration

```lua
-- Standard spawn call:
TerminatorSpawner.spawnTerminator(x, y, z, {
    isFemale = false,                  -- Boolean
    forename = "The",                  -- String
    surname = "Terminator",            -- String
    initialGoals = {                   -- GOAP goals
        ELIMINATE_PLAYER = 10
    }
})

-- Returns: (agent, agentID)
```

---

## Debugging Tips

### Check if agent spawned:
```lua
local agent = TerminatorSpawner.getAgent("Terminator_1000")
if agent then
    print("Agent spawned: " .. agent.agentID)
    print("Position: " .. agent.savedX .. ", " .. agent.savedY)
end
```

### Check all agents:
```lua
local agents = TerminatorSpawner.getAllAgents()
for agentID, agent in pairs(agents) do
    print(agentID .. " -> alive: " .. tostring(agent.isAlive))
end
```

### Watch the log for:
- `[Spawner] Server started - initializing Terminator agents`
- `[Spawner] Creating Terminator agent 'Terminator_1000' at 100,100,0`
- `[Spawner] Agent 'Terminator_1000' spawned successfully`
- `[Spawner] Game saving - persisting Terminator agents`
- `[Spawner] Game started - loading saved Terminator agents`
- `[Spawner] Restoring agent 'Terminator_1000'`

---

## Known Limitations & Future Improvements

1. **Navigation Graph Rebuild**: Currently rebuilt on every load (~1 second). Could be optimized by caching.
2. **IsoPlayer Inventory**: Inventory/clothing/traits are not yet persisted (requires `IsoPlayer:save(fileName)` integration).
3. **Multiple Agents**: Framework supports N agents; only 1 spawned by default. Can easily spawn more by calling `spawnTerminator()` multiple times.
4. **Agent State Machine**: Currently relies on `spawned` flag; could add more granular lifecycle states if needed.

---

## Summary

✅ **Spawning** - Uses PZNS-proven `IsoPlayer.new()` pattern
✅ **Persistence** - ModData-based like PZNS; survives save/load
✅ **Events** - Hooked to OnServerStarted, OnGameStart, OnSave
✅ **Pathfinding** - Built on-demand; ready before agent acts
✅ **Debuggable** - Clear function names, logging, and state tracking

The Terminator NPC will now:
- Spawn correctly on server start
- Persist when you save/exit
- Restore at exact position/state when you load the save
- Remain compatible with Project Zomboid's save system
