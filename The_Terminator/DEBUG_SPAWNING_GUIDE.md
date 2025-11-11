# Terminator NPC Debug Spawning Guide

## Quick Start: Spawn Terminator in Debug Mode

### Enable Debug Mode in Project Zomboid
1. Open mod menu → Mods
2. Find "Terminator" 
3. Enable it
4. In your Sandbox Options, enable **Debug Mode** (or use console with `/`)

### Console Commands

**Open console:** Press `;` key during gameplay

#### Spawn at Player Location (offset by 5 squares)
```
/c TerminatorSpawner.debugSpawnAtPlayer()
```
Spawns the Terminator 5 squares away from your current position.

#### Spawn at Specific Coordinates
```
/c TerminatorSpawner.debugSpawnAtCoords(100, 100, 0)
```
Replace `100, 100, 0` with your desired X, Y, Z coordinates.

#### List All Active Agents
```
/c TerminatorSpawner.debugListAgents()
```
Shows all spawned Terminator agents with their status (ALIVE/DEAD) and position.

**Example output:**
```
[Spawner DEBUG] Active Terminator Agents:
  Terminator_1000 [ALIVE] at 105, 105, 0
  Terminator_1001 [ALIVE] at 200, 150, 0
```

#### Kill All Agents
```
/c TerminatorSpawner.debugKillAll()
```
Immediately kills all spawned Terminator NPCs.

---

## How It Works (Like PZNS_Framework)

PZNS_Framework allows spawning NPCs via console in debug mode. The Terminator mod follows the same pattern:

### PZNS Example
In PZNS_Framework, you'd do something like:
```
/c PZNS_NPCsManager.createNPCSurvivor(survivorID, isFemale, surname, forename, square, ...)
```

### Terminator Implementation
We expose similar public functions:
- `TerminatorSpawner.debugSpawnAtPlayer()` - Spawn near you
- `TerminatorSpawner.debugSpawnAtCoords(x, y, z)` - Spawn anywhere
- `TerminatorSpawner.debugListAgents()` - Inspect agents
- `TerminatorSpawner.debugKillAll()` - Test death logic

---

## Spawn Options

All debug spawn commands create a Terminator with these default settings:
```lua
{
    isFemale = false,
    forename = "The",
    surname = "Terminator",
    initialGoals = { ELIMINATE_PLAYER = 10 }
}
```

To customize, edit `TerminatorSpawner.lua` and modify the config inside `debugSpawnAtPlayer()` or `debugSpawnAtCoords()`.

---

## Common Workflows

### Test NPC Spawning
```
/c TerminatorSpawner.debugSpawnAtPlayer()
```
Check console for: `[Spawner DEBUG] Terminator spawned successfully with ID: Terminator_1000`

### Verify NPC Persists
1. Spawn: `/c TerminatorSpawner.debugSpawnAtPlayer()`
2. Save game (Ctrl+S or via menu)
3. Reload (exit and re-enter)
4. Check: `/c TerminatorSpawner.debugListAgents()`
   - If Terminator_1000 shows [ALIVE], persistence works! ✓

### Test Multiple Agents
```
/c TerminatorSpawner.debugSpawnAtCoords(100, 100, 0)
/c TerminatorSpawner.debugSpawnAtCoords(150, 150, 0)
/c TerminatorSpawner.debugSpawnAtCoords(200, 200, 0)
/c TerminatorSpawner.debugListAgents()
```

### Clean Up
```
/c TerminatorSpawner.debugKillAll()
```

---

## Troubleshooting

### "No player found" error
- Make sure you're in a loaded game (not main menu)
- Ensure your character is spawned

### "Failed to spawn Terminator"
- Check if the coordinates are valid (not out of map)
- Ensure no terrain/obstacles at spawn location
- Check game log for more details

### Spawned but can't see the NPC?
- Terminator spawns 5 squares away by default in `debugSpawnAtPlayer()`
- Use `/c TerminatorSpawner.debugListAgents()` to verify position
- Check if NPC is off-screen

---

## Disable Auto-Spawn on Server Start

By default, the Terminator spawns automatically on server start. To disable and only use debug spawning:

Edit `TerminatorSpawner.lua`, find the `onServerStarted()` function:

```lua
local function onServerStarted()
    print("[Spawner] Server started - initializing Terminator agents")
    
    -- Comment out the line below to disable auto-spawn
    -- TerminatorSpawner.spawnTerminator(100, 100, 0, { ... })
end
```

Now NPCs only spawn via debug commands.

---

## Advanced: Add Custom Spawning to Context Menu

If you want right-click context menu spawning (like PZNS has), we can add that. For now, console commands are the fastest way to test.

Reference: `PZNS_Framework/media/lua/client/08_mod_contextmenu/` has context menu examples if you want to implement it later.
