# Aaron_Framework (Terminator-project)

Lightweight Project Zomboid NPC framework used by the "Terminator" mod.  
Provides NPC representation, GOAP planning, GOAP actions/goals, and common utilities.

---

## Overview

This repo implements:
- NPC data & managers (spawn, groups, zones)
- GOAP planner + world-state builder
- Action implementations (movement, combat, scavenge, etc.)
- Utilities for world math, inventory, debugging, and mod options

Primary purpose: drive NPC behaviours (follow, hunt, scavenge, fight) with a GOAP layer that uses action modules and a world state snapshot.

---

## Quick start / install

1. Copy the `Aaron_Framework` folder to your Project Zomboid `mods` directory.
   - Windows default location typically:
     - `%USERPROFILE%\Zomboid\mods\`
2. Enable the mod in the game's Mods UI and restart the game.
3. Use sandbox options in `media/sandbox-options.txt` to change runtime flags.

---

## Repo layout (important folders)

- media/lua/client/
  - 00_references: mod init files
  - 01_mod_options: sandbox options / settings
  - 02_mod_utils: utilities (WorldUtils, NPC helpers, debug)
  - 03_mod_core: NPC classes and presets
  - 04_data_management: NPC managers, persistence
  - 05_npc_actions: timed actions and GOAP actions (movement, weapon, scavenge)
    - GOAP_Actions/: GOAP action modules (used by planner/runtime)
  - 07_npc_ai: GOAP planner, world-state builder, jobs & top-level AI
    - GOAP_GOALS/: goal modules
  - other supporting folders (06_npc_orders, UI, etc.)

---

## GOAP: how it works (short)

1. `PZNS_GOAPWorldState.buildWorldState(npc, opts)` produces a snapshot table of boolean/primitive predicates.
2. `PZNS_GOAPPlanner.planForNPC(npc, goalOrDesired)` builds world state and runs A* over registered action modules to produce a plan.
3. Actions are plain Lua modules that expose:
   - `name` (string)
   - `preconditions` (table)
   - `effects` (table)
   - `cost` (number, optional)
   - (optional) runtime perform/execute methods for side effects
4. Goals expose `getDesiredState(npc)` returning a table of desired predicates.

Important: predicate keys must match exactly across world state, action effects and goal desired-state (e.g. `isWeaponEquipped`).

---

## How to register actions and goals

Create a small init file to require your GOAP modules and register them with the planner (example `PZNS_GOAPInit.lua`). Basic pattern:

```lua
local Planner = require("07_npc_ai/PZNS_GOAPPlanner")

local actionFiles = {
  "05_npc_actions/GOAP_Actions/GOAP_Hunt_Player",
  -- add others...
}

for _, f in ipairs(actionFiles) do
  local ok, mod = pcall(require, f)
  if ok and type(mod) == "table" then
    Planner.registerAction(mod)
  end
end

local goalFiles = {
  "07_npc_ai/GOAP_GOALS/Goal_GetWeapon",
}

for _, f in ipairs(goalFiles) do
  local ok, mod = pcall(require, f)
  if ok and type(mod) == "table" then
    Planner.registerGoal(mod)
  end
end
```

Call this init from `BaseReferences.lua` or your mod init so registration happens on startup.

---

## Movement / worldstate markers

- Movement actions should set markers on the NPC so the world state can detect "has queued movement":
  - `npcSurvivor.walkToX/Y/Z` for walk actions
  - `npcSurvivor.runToX/Y/Z` for run actions
  - Clear markers in action `perform()` and `stop()` to avoid stale data.
- `PZNS_GOAPWorldState.buildWorldState` reads those markers and computes:
  - `isWalkToLocationAvailable`, `hasReachedWalkToLocation`
  - `isRunToLocationAvailable`, `hasReachedRunToLocation`

---

## Debugging & performance

- Planner can be expensive. Use the planner perf knobs in `PZNS_GOAPPlanner.lua`:
  - `MAX_GOAP_ITERATIONS` — cap node expansions per plan call (lower to reduce CPU)
  - `DEBUG_GOAP_PLANNER` — enable verbose traces (slower)
- Planner prints a perf line per plan call:
  - `[GOAP PERF] buildWorldState=%.1fms plan=%.1fms total=%.1fms iterations=%d open=%d closed=%d`
- If planner fails with "OPEN LIST EMPTY" check:
  - predicate name mismatches (e.g. `hasWeaponEquipped` vs `isWeaponEquipped`)
  - missing/incorrect action registration
  - actions with incorrect `preconditions`/`effects`
- To search the codebase on Windows (PowerShell):
```powershell
Get-ChildItem -Recurse -Filter *.lua | Select-String -Pattern "lastKnownPlayerX|isTargetVisible" | Format-Table Path, LineNumber, Line -AutoSize
```

---

## Quick test helper (how to run)

A small helper `PZNS_TestGOAPHuntPlayer(npcSurvivor, targetID)` was added for quick checks. You can call it from code (e.g. a one-off mod init snippet) to print the action result and NPC markers.

Example usage in Lua code:
```lua
local Tester = require("07_npc_ai/PZNS_JobTerminator") -- or wherever you put test helper
Tester.PZNS_TestGOAPHuntPlayer(someNpcSurvivor, "Player0")
```

(You can add a temporary call in `BaseReferences.lua` for quick in-game testing; remove it after.)

---

## Tips & best practices

- Standardize predicate names early and use shared constants to avoid planner mismatches.
- Keep actions minimal and only register actions you implement to limit branching.
- Keep `buildWorldState` lightweight — compute only predicates the planner needs.
- Use markers on `npcSurvivor` for movement/scavenge targets rather than embedding logic in worldState.
- Clear markers on action completion/abort to avoid stale planner input.

---

## Contact / contribution

- This README is generated from the project tree in `media/lua/client/`. For patches, edit modules under `05_npc_actions` and `07_npc_ai`.
- If you want, I can generate:
  - A starter `PZNS_GOAPInit.lua` that registers all found actions/goals
  - A standard `GOAP_Action_Template.lua` and `GOAP_Goal_Template.lua`
  - A derived `PZNS_WalkToTimedAction` class that auto-sets/clears markers

---

License: keep with your mod license. Contributions/fixes should follow Project Zomboid modding best practices.