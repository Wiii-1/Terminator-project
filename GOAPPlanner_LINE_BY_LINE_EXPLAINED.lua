-- ============================================
-- LINE-BY-LINE DETAILED BREAKDOWN: PZNS_GOAPPlanner
-- ============================================

--[[
This file explains every single line of the planner code in excruciating detail.
Read this to truly understand how GOAP works in your system.
]]

-- ============================================
-- SECTION 1: MODULE LOADING
-- ============================================

-- LINE 1-3: Load all available actions
local actions = {
	require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponAiming"),
	require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponRangedAttack"),
	require("05_npc_actions/GOAP_Actions/PZNS_GOAP_WeaponReload"),
}

--[[
WHAT: Creates a table called `actions` containing three action modules
WHY: These are all the actions the planner can choose from
HOW:
  - require(...) loads a Lua file and returns what it exports
  - Each file exports an action module like:
    {
      name = "WeaponAiming_Action",
      cost = 6,
      preconditions = { hasWeaponEquipped = true, ... },
      effects = { isWeaponAimed = true },
      perform = function(npc) ... end
    }
  - The three actions are stored in a table as items 1, 2, 3

ANALOGY:
  Think of this like: "Here are all the moves a chess piece can make"
  actions[1] = Aim
  actions[2] = Attack
  actions[3] = Reload

LATER USE:
  When planning, we loop through `actions` to find valid moves
]]

-- LINE 5-6: Load goal and world state utilities
local PZNS_Goal = require("07_npc_ai/PZNS_Goal")
local PZNS_GOAPWorldState = require("07_npc_ai/PZNS_GOAPWorldState")

--[[
WHAT: Load helper modules
WHY: We need these for building world states and checking goals

PZNS_Goal:
  Defines the goal structure/interface
  Not directly used in this file, but imported for consistency

PZNS_GOAPWorldState:
  Has buildWorldState() function
  Converts NPC's current situation into a state table
  Example: { isWeaponEquipped=true, hasAmmo=false, ... }
]]

-- LINE 8: Create empty planner module
local PZNS_GOAPPlanner = {}

--[[
WHAT: Create an empty table to hold all planner functions
WHY: This is the module we'll return at the end
HOW: All functions will be added as PZNS_GOAPPlanner.functionName = function(...)

At the end: return PZNS_GOAPPlanner
So other files can do: local planner = require("PZNS_GOAPPlanner")
                      planner.plan(...)
                      planner.planForNPC(...)
]]

-- LINE 10-15: Load all available goals
local goals = {
	-- require each goal module you have here
	require("07_npc_ai/GOAP_GOALS/GetWeapon_Goal"),
	require("07_npc_ai/GOAP_GOALS/killPlayer_Goal"),
	-- add more goal modules as you create them
}

--[[
WHAT: Table of all goal modules
WHY: These define what the NPC might want to achieve
HOW:
  Each goal exports a module like:
  {
    name = "killPlayer",
    priority = function(npc) return 10 end,
    isValid = function(npc) return npc.hasTarget end,
    getDesiredState = function(npc) return { isTargetDead = true } end
  }

ANALOGY:
  Think of this like: "What does the NPC want to do?"
  goals[1] = "Get a weapon"
  goals[2] = "Kill the player"

LATER USE:
  We'll select the best goal based on priority
  Then get what that goal's desired state is
]]

-- ============================================
-- SECTION 2: PUBLIC FUNCTIONS (API)
-- ============================================

-- LINE 17-19: Get all goals
local M = {}

function M.getGoals()
	return goals
end

--[[
NAME: M.getGoals()
PURPOSE: Return all goal modules
RETURNS: The `goals` table

USAGE: local allGoals = planner.getGoals()
       print(#allGoals) → prints 2 (GetWeapon, killPlayer)

WHY: Allow other files to access all available goals
]]

-- LINE 21-27: Get only VALID goals
function M.geValidGoals()  -- NOTE: Typo in name (should be "getValidGoals")
	local validGoals = {}
	for _, goal in ipairs(goals) do
		if goal.isValid() then
			table.insert(validGoals, goal)
		end
	end
	return validGoals
end

--[[
NAME: M.geValidGoals() [TYPO: should be getValidGoals]
PURPOSE: Filter goals to only those that are currently valid

LINE 22: local validGoals = {}
         Create empty table to store valid goals

LINE 23: for _, goal in ipairs(goals) do
         Loop through each goal in the goals table
         _ means we ignore the index (1, 2, 3)
         goal = current goal module

LINE 24: if goal.isValid() then
         Check if this goal's isValid() function returns true
         Each goal module should have isValid(npc) function
         Returns true if goal makes sense right now

LINE 25: table.insert(validGoals, goal)
         Add this valid goal to our validGoals table

LINE 28: return validGoals
         Return only the goals that are valid

EXAMPLE:
  If killPlayer_Goal.isValid() = false (no target)
  But GetWeapon_Goal.isValid() = true (has inventory)
  Returns: { GetWeapon_Goal }

ISSUE: This function doesn't take an NPC parameter!
       Should be: function M.geValidGoals(npc)
                    if goal.isValid(npc) then
       Current code just calls goal.isValid() with no arguments
]]

-- LINE 29-41: SELECT BEST GOAL BY PRIORITY
function M.selectBest(npc)
	local selectBestGoal = nil
	local highestPriority = -math.huge
	
	for _, goal in ipairs(goals) do
		if goal.isValid(npc) then
			local priority = goal.priority(npc)
			if priority > highestPriority then
				highestPriority = priority
				selectBestGoal = goal
			end
		end
	end
	
	return selectBestGoal
end

--[[
NAME: M.selectBest(npc)
PURPOSE: Find the BEST goal for this NPC right now
RETURNS: The goal module with highest priority, or nil if no valid goals

LINE 30: local selectBestGoal = nil
         Holder for the best goal we find
         Starts as nil

LINE 31: local highestPriority = -math.huge
         Holds the highest priority number we've seen
         -math.huge = negative infinity (extremely low number)
         So ANY priority will be higher than this

STEP-BY-STEP EXECUTION:
========================

Goal 1: GetWeapon_Goal
  ├─ goal.isValid(npc) → true (missing weapon)
  ├─ priority = goal.priority(npc) → 5
  ├─ 5 > -math.huge? YES ✓
  ├─ highestPriority = 5
  └─ selectBestGoal = GetWeapon_Goal

Goal 2: killPlayer_Goal
  ├─ goal.isValid(npc) → true (target visible)
  ├─ priority = goal.priority(npc) → 10
  ├─ 10 > 5? YES ✓
  ├─ highestPriority = 10
  └─ selectBestGoal = killPlayer_Goal

RETURN: killPlayer_Goal (highest priority)

WHY THIS WORKS:
  - We start with -math.huge so first goal always wins
  - Each subsequent goal must beat the current highest
  - Final result is goal with truly highest priority

ANALOGY:
  Like picking the most important task from your todo list:
  - Task 1: "Reply to email" (priority 5)
  - Task 2: "Kill threatening enemy" (priority 10) ← PICK THIS
  - Task 3: "Organize inventory" (priority 3)

ALTERNATIVE NAMES FOR THIS PATTERN:
  - "max()" function - find maximum value
  - "tournament selection" - each goal competes
  - "greedy algorithm" - always pick highest priority
]]

-- ============================================
-- SECTION 3: UTILITY FUNCTIONS (HELPERS)
-- ============================================

-- LINE 43-49: Deep copy state table
local local_copyState = function(s)
	local t = {}
	for k, v in pairs(s or {}) do
		t[k] = v
	end
	return t
end

--[[
NAME: local_copyState(s)
PURPOSE: Create a copy of a state table
RETURNS: New table with same contents

WHY WE NEED THIS:
  When we modify a state in A* search, we don't want to modify the original
  If state = { weapon=true, ammo=false }
  And we apply an effect: weapon = false
  We need a NEW state, not the original modified

HOW IT WORKS:
  Input:  s = { isWeaponEquipped = true, hasAmmo = false }
  
  Line 44: local t = {}
           Create empty table
  
  Line 45-47: for k, v in pairs(s or {})
              s or {} means: if s is nil, use empty table
              Loop through each key-value pair
              k = key (like "isWeaponEquipped")
              v = value (like true)
  
  Line 46: t[k] = v
           Copy the value into new table t
           t[isWeaponEquipped] = true
           t[hasAmmo] = false
  
  Line 48: return t
           Return the copied table

OUTPUT: t = { isWeaponEquipped = true, hasAmmo = false }
        (Different table object, same contents)

IMPORTANCE:
  This is CRITICAL for A* search
  Without copying, modifying one path would affect all paths
  With copying, each path has its own independent state

VISUAL:
  Original:  state = { a=1, b=2 }
             ↓ copyState
  Copy:      newState = { a=1, b=2 }
             (Different object, same values)
  
  If we modify copy: newState.a = 999
  Original stays: state = { a=1, b=2 }
]]

-- LINE 51-60: Check if preconditions are met
local local_meetsPreconditions = function(state, pre)
	if not pre then
		return true
	end
	for k, v in pairs(pre) do
		if state[k] ~= v then
			return false
		end
	end
	return true
end

--[[
NAME: local_meetsPreconditions(state, pre)
PURPOSE: Check if all preconditions in `pre` are satisfied in `state`
RETURNS: true if all preconditions met, false otherwise

WHY:
  Actions have prerequisites. Can't attack if not aiming.
  Example WeaponRangedAttack preconditions:
  {
    hasWeaponEquipped = true,
    isWeaponAimed = true,
    hasAmmoInChamber = true,
    isTargetVisible = true
  }

HOW IT WORKS:

INPUT 1:
  state = { hasWeaponEquipped=true, isWeaponAimed=true, hasAmmoInChamber=false }
  pre = { hasWeaponEquipped=true, isWeaponAimed=true, hasAmmoInChamber=true }

EXECUTION:
  Line 52: if not pre then return true
           If no preconditions, always valid ✓
  
  Line 54-57: Loop through preconditions
    pre[hasWeaponEquipped] = true
      → state[hasWeaponEquipped] = true
      → true == true? YES, continue
    
    pre[isWeaponAimed] = true
      → state[isWeaponAimed] = true
      → true == true? YES, continue
    
    pre[hasAmmoInChamber] = true
      → state[hasAmmoInChamber] = false
      → true == false? NO ✗
      → Line 56: return false (PRECONDITION NOT MET)

RETURN: false (Can't execute this action, missing ammo in chamber)

ANOTHER EXAMPLE - ALL MET:
  state = { weapon=true, aimed=true, ammo=true }
  pre = { weapon=true, aimed=true, ammo=true }
  
  All checks pass → Line 58: return true

KEY CONCEPT:
  This is the "gate" that decides if an action can be executed
  Only actions whose preconditions are met can be added to the plan
]]

-- LINE 62-70: Apply effects to create new state
local local_applyEffects = function(state, effects)
	local ns = local_copyState(state)
	for k, v in pairs(effects or {}) do
		ns[k] = v
	end
	return ns
end

--[[
NAME: local_applyEffects(state, effects)
PURPOSE: Apply action effects to a state to create a new state
RETURNS: New state with effects applied

WHY:
  When we execute an action, the world changes
  Executing "WeaponAiming" sets isWeaponAimed = true
  We need to create the NEW state after the action

HOW IT WORKS:

INPUT:
  state = { hasWeaponEquipped=true, isWeaponAimed=false, hasAmmoInChamber=false }
  effects = { isWeaponAimed=true }

EXECUTION:
  Line 63: local ns = local_copyState(state)
           Copy current state
           ns = { hasWeaponEquipped=true, isWeaponAimed=false, hasAmmoInChamber=false }
  
  Line 64-66: Loop through effects
    k = "isWeaponAimed", v = true
    ns[isWeaponAimed] = true
    Now ns = { hasWeaponEquipped=true, isWeaponAimed=true, hasAmmoInChamber=false }
  
  Line 67: return ns
           Return modified copy

OUTPUT: ns = { hasWeaponEquipped=true, isWeaponAimed=true, hasAmmoInChamber=false }

IMPORTANT: 
  We DON'T modify the original state
  We return a NEW state
  Original state stays unchanged

ANALOGY:
  Current world: { weapon=true, aiming=false, ammo=false }
  Action: Aim at target
  After action: { weapon=true, aiming=true, ammo=false }
  The aiming property changed, but weapon and ammo are same
]]

-- LINE 72-88: Hash state to detect revisits
local local_stateHash = function(state)
	local keys = {}
	for k, _ in pairs(state or {}) do
		table.insert(keys, k)
	end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do
		parts[#parts + 1] = k .. ":" .. tostring(state[k])
	end
	return table.concat(parts, "|")
end

--[[
NAME: local_stateHash(state)
PURPOSE: Convert state table to unique string key
RETURNS: String representation of state

WHY:
  In A* search, we use a `closed` set to track visited states
  We can't use table objects as keys (they're objects, not values)
  We need a way to identify: "Have we seen this state before?"
  Solution: Convert state to unique string

HOW IT WORKS:

INPUT:
  state = { isWeaponEquipped=true, isTargetDead=false, hasAmmo=true }

STEP 1: Extract keys (Line 73-76)
  local keys = {}
  Loop through state pairs
  keys = { "isWeaponEquipped", "isTargetDead", "hasAmmo" }

STEP 2: Sort keys (Line 77)
  table.sort(keys)
  keys = { "hasAmmo", "isTargetDead", "isWeaponEquipped" }
  WHY SORT? So same state always produces same hash
  Different order would give different string

STEP 3: Build string parts (Line 78-82)
  local parts = {}
  For each key:
    "hasAmmo" → parts = { "hasAmmo:true" }
    "isTargetDead" → parts = { "hasAmmo:true", "isTargetDead:false" }
    "isWeaponEquipped" → parts = { "hasAmmo:true", "isTargetDead:false", "isWeaponEquipped:true" }

STEP 4: Concatenate with | (Line 83)
  table.concat(parts, "|")
  Result: "hasAmmo:true|isTargetDead:false|isWeaponEquipped:true"

RETURN: "hasAmmo:true|isTargetDead:false|isWeaponEquipped:true"

WHY THIS MATTERS:
  If we see this exact string again in closed set
  We know we've explored this state before
  So we don't explore it again (avoids infinite loops)

ANALOGY:
  Like taking a photo of a chess board position
  Then later: "Have we been here before?" → Compare photos
  If photos match, we've been here
]]

-- LINE 90-99: Calculate heuristic distance to goal
local local_heuristic = function(state, goal)
	local n = 0
	for k, v in pairs(goal or {}) do
		if state[k] ~= v then
			n = n + 1
		end
	end
	return n
end

--[[
NAME: local_heuristic(state, goal)
PURPOSE: Estimate how far we are from the goal
RETURNS: Number of goal predicates that don't match current state

WHY:
  A* algorithm needs an estimate of remaining cost
  This estimate helps A* explore better paths first
  Better estimate = fewer nodes explored = faster planning

HOW IT WORKS:

INPUT:
  state = { isWeaponEquipped=true, isTargetDead=false, hasAmmo=false }
  goal = { isTargetDead=true, hasAmmo=true }

EXECUTION:
  Line 92: local n = 0
           Counter for mismatches
  
  Line 93-97: Loop through goal predicates
    
    Goal: isTargetDead=true
      state[isTargetDead] = false
      false != true? YES, mismatch
      n = 1
    
    Goal: hasAmmo=true
      state[hasAmmo] = false
      false != true? YES, mismatch
      n = 2
  
  Line 98: return n

RETURN: 2

MEANING:
  We need to satisfy 2 more goal predicates
  Estimate: minimum 2 more actions needed
  (Actual answer could be more)

ANOTHER EXAMPLE:
  state = { isTargetDead=true, hasAmmo=true }
  goal = { isTargetDead=true, hasAmmo=true }
  
  Both match perfectly → n = 0
  INTERPRETATION: We're at the goal! ✓

ALGORITHM USAGE:
  f = g + h
  g = actual cost to reach this state from start
  h = heuristic estimate to goal
  
  States with lower f are explored first
  Heuristic guides search toward goal
]]

-- ============================================
-- SECTION 4: MAIN A* ALGORITHM
-- ============================================

-- LINE 101-151: The A* search algorithm
function PZNS_GOAPPlanner.plan(worldState, goal, actionList)
	local available = actions
	if not worldState or not goal then
		return nil
	end

--[[
NAME: PZNS_GOAPPlanner.plan(worldState, goal, actionList)
PURPOSE: Find a sequence of actions to reach goal from worldState
RETURNS: Array of actions [Action1, Action2, ...] or nil if impossible

PARAMETERS:
  worldState: Current state table { predicate=value, ... }
  goal: Desired state table { predicate=value, ... }
  actionList: Optional custom actions (default: global `actions`)

LINE 103: local available = actions
          Decide which actions to use
          If actionList provided, should use it (but doesn't! BUG)
          Currently always uses global `actions`

LINE 104-106: Input validation
  if not worldState or not goal then return nil end
  If either input is missing, can't proceed
  Return nil (failure)

A* ALGORITHM OVERVIEW:
======================
A* explores possible states using:
1. open list: States to explore (priority queue)
2. closed set: States already explored
3. Sort by f = g + h (cost + heuristic)
4. Find path when goal reached

Continue reading for detailed line-by-line breakdown...
]]

	local open = {}
	local closed = {}

--[[
LINE 108-109: Initialize data structures

Line 108: local open = {}
          Table for states to explore
          Will be sorted by priority (f = g + h)
          Start with most promising states first

Line 109: local closed = {}
          Table/set for explored states
          Key: state hash (string)
          Value: true
          Purpose: Don't revisit same state twice

ANALOGY:
  open = TODO list of states to check
  closed = DONE list of states we've checked
]]

	table.insert(open, { state = local_copyState(worldState), g = 0, h = local_heuristic(worldState, goal), plan = {} })

--[[
LINE 110: Initialize open list with starting node

What's inserted:
  {
    state = copy of worldState,
    g = 0,                        (cost from start to here)
    h = heuristic to goal,        (estimate from here to goal)
    plan = {}                     (actions taken so far: none)
  }

Detail breakdown:
  state = local_copyState(worldState)
    → Copy the initial world state
    → Don't modify original

  g = 0
    → At the start, we've taken 0 cost
    → No actions executed yet

  h = local_heuristic(worldState, goal)
    → Calculate distance from start to goal
    → How many predicates don't match?

  plan = {}
    → We haven't executed any actions yet
    → Empty plan

f = g + h = 0 + h = h (just the heuristic at start)

EXAMPLE:
  worldState = { weapon=false, ammo=false, aiming=false }
  goal = { weapon=true, ammo=true, aiming=true }
  
  Node = {
    state = { weapon=false, ammo=false, aiming=false },
    g = 0,
    h = 3,  (all 3 predicates differ)
    plan = {}
  }
]]

	while #open > 0 do

--[[
LINE 111: Main A* loop

#open = number of items in open list
While there are unexplored states...

Loop continues until:
  - Goal found and returned (success)
  - open list becomes empty (failure - return nil at end)
]]

		table.sort(open, function(a, b)
			return (a.g + a.h) < (b.g + b.h)
		end)

--[[
LINE 112-114: Sort open list by f-score

table.sort(open, ...) 
  → Sorts the open list

Comparison function:
  function(a, b) return (a.g + a.h) < (b.g + b.h) end
  
  For each pair of nodes:
  a.g + a.h = f-score of node a
  b.g + b.h = f-score of node b
  
  Return true if a should come before b
  (i.e., if a's f-score is smaller than b's)

RESULT:
  open[1] has smallest f-score
  open[2] has next smallest
  etc.

EXAMPLE BEFORE SORT:
  open[1]: f = 10 + 5 = 15
  open[2]: f = 2 + 8 = 10
  open[3]: f = 3 + 6 = 9

AFTER SORT:
  open[1]: f = 9   ← Best
  open[2]: f = 10
  open[3]: f = 15

WHY SORT?
  A* always explores the most promising state first
  States with lowest f-score are closest to goal
  (Or seem to be, based on heuristic)
]]

		local node = table.remove(open, 1)

--[[
LINE 115: Pop best node

table.remove(open, 1)
  → Remove and return first item from open
  → Since open is sorted, first item has best f-score

RESULT:
  node = the state we'll explore next

This node had:
  - Lowest f-score in open list
  - Most promising state to explore
]]

		if local_heuristic(node.state, goal) == 0 then
			return node.plan
		end

--[[
LINE 116-118: Check if goal reached

if local_heuristic(node.state, goal) == 0 then
  → Calculate heuristic distance
  → If 0, all goal predicates match!

  return node.plan
  → Goal found! Return the plan

WHAT GETS RETURNED:
  node.plan = [Action1, Action2, Action3, ...]
  The sequence of actions to reach goal

EXAMPLE:
  If we explored Aim → Reload → Attack
  And found that Attack makes target dead
  And dead is the goal
  
  node.plan = [Aim, Reload, Attack]
  
  RETURN: [Aim, Reload, Attack]
  ← This is the answer!

This is how A* ends: finding a node where heuristic = 0
]]

		local nodeHash = local_stateHash(node.state)
		if not closed[nodeHash] then
			closed[nodeHash] = true

--[[
LINE 119-121: Add to closed set

nodeHash = local_stateHash(node.state)
  → Convert state to unique string key

if not closed[nodeHash] then
  → If we haven't seen this state before...

  closed[nodeHash] = true
  → Mark it as seen now

PURPOSE: Avoid exploring same state twice
MECHANISM: Use hash table with state strings as keys

FLOW:
  First time we see state X:
    closed[hash_of_X] doesn't exist
    We mark: closed[hash_of_X] = true
    Continue exploring this state
  
  Later, if we generate state X again:
    closed[hash_of_X] exists (it's true)
    Skip it (don't add to open list)

PREVENTS: Infinite loops, wasted exploration

EXAMPLE:
  Scenario 1: Aim → Reload → Attack → (no ammo) → Reload again
  
  When we reach "no ammo" second time:
  nodeHash = "ammo:false|aimed:true|..."
  This hash was seen before
  Skip it, don't add to open list

EFFICIENCY:
  Without closed set: Could explore same state forever
  With closed set: Each state explored exactly once
]]

			for _, act in ipairs(available) do
				if act and local_meetsPreconditions(node.state, act.preconditions) then

--[[
LINE 122-123: Loop through all available actions

for _, act in ipairs(available) do
  → For each action in our action list
  → available = global actions table

if act and local_meetsPreconditions(node.state, act.preconditions) then
  → Check two things:
    1. act exists (not nil)
    2. Current state satisfies action's preconditions

Only if BOTH true, we can execute this action
]]

					local newState = local_applyEffects(node.state, act.effects)

--[[
LINE 124: Apply action effects

newState = local_applyEffects(node.state, act.effects)
  → Create new state by applying action effects
  → Simulates: "What would happen if we execute this action?"

EXAMPLE:
  Current state: { weapon=true, ammo=false, aimed=false }
  Action: Reload
  Effects: { ammo=true }
  
  newState = { weapon=true, ammo=true, aimed=false }
  
  The state we'd reach if we reload
]]

					local newPlan = {}
					for i = 1, #node.plan do
						newPlan[i] = node.plan[i]
					end
					table.insert(newPlan, act)

--[[
LINE 125-129: Build new plan

newPlan = {} 
  → Create empty new plan

for i = 1, #node.plan do
  newPlan[i] = node.plan[i]
end
  → Copy all actions from current plan
  → If current plan = [Aim, Reload]
  → newPlan = [Aim, Reload]

table.insert(newPlan, act)
  → Add this action to the end
  → If we execute Aim now
  → newPlan = [Aim, Reload, Aim]

RESULT:
  newPlan = current plan + this new action
  
ANALOGY:
  Current plan: "Take stairs, go right"
  New action: "Open door"
  New plan: "Take stairs, go right, open door"
]]

					local g2 = node.g + (act.cost or 1)

--[[
LINE 130: Calculate new cost

g2 = node.g + (act.cost or 1)
  → g2 = new g value for successor node

node.g = cost to reach current node
act.cost = cost of this action (default 1 if not specified)
g2 = total cost if we take this action

EXAMPLE:
  node.g = 7  (took 7 cost to get here)
  act.cost = 4  (this action costs 4)
  g2 = 7 + 4 = 11

ACTION COSTS:
  WeaponAiming: cost = 6
  WeaponReload: cost = 7
  WeaponRangedAttack: cost = 4
  
  So different actions have different priorities
  Cheaper actions preferred by planner
]]

					local nhash = local_stateHash(newState)
					if not closed[nhash] then

--[[
LINE 131-132: Check if new state was visited

nhash = local_stateHash(newState)
  → Hash of the state we'd reach

if not closed[nhash] then
  → If we haven't explored this state before...

LOGIC:
  We generated newState by executing action on node.state
  But maybe this state was reached through different path already
  If so, closed[nhash] would be true
  And we skip it (no point exploring twice)
  
  If it wasn't explored, we add it to open list

PREVENTS: Exploring same state multiple times
]]

						table.insert(
							open,
							{ state = newState, g = g2, h = local_heuristic(newState, goal), plan = newPlan }
						)

--[[
LINE 133-137: Add new state to open list

table.insert(open, {...})
  → Add new search node to open list

The node contains:
  state = newState
    → The state after executing this action
  
  g = g2
    → Total cost to reach this state
  
  h = local_heuristic(newState, goal)
    → Estimated cost from here to goal
  
  plan = newPlan
    → Sequence of actions to reach this state

NEW f-SCORE = g + h = g2 + h

EXAMPLE:
  Current node: f = 5, plan = [Aim]
  Execute Reload (cost 7):
    newState = { ammo=true, ... }
    g2 = 5 + 7 = 12
    h = 1 (one predicate away from goal)
    f = 12 + 1 = 13
    plan = [Aim, Reload]
  
  Next iteration, this becomes a candidate
  And is sorted with f = 13
  Compared to other candidates
]]

					end
				end
			end
		end
		return nil
	end
end

--[[
REMAINING LINES (138-143):

Line 138: end (closes: if not closed[nhash])
Line 139: end (closes: for act in actions)
Line 140: end (closes: if not closed[nodeHash])
Line 141: end (closes: while #open > 0)
Line 142: return nil (goal never found, open list became empty)
Line 143: end (closes: function PZNS_GOAPPlanner.plan)

REACHING "return nil":
  All nodes explored (open list empty)
  Goal was never reached
  No plan exists for this goal
]]

-- ============================================
-- SECTION 5: HIGH-LEVEL PLANNING (CONVENIENCE)
-- ============================================

function PZNS_GOAPPlanner.planForNPC(npcSurvivor, goalOrDesired, actionList)
	local ws = PZNS_GOAPWorldState.buildWorldState(npcSurvivor, { heavyScan = false })
	if not ws then
		print("PZNS_GOAPPlanner: failed to build world state")
		return nil
	end

--[[
NAME: PZNS_GOAPPlanner.planForNPC(npcSurvivor, goalOrDesired, actionList)
PURPOSE: High-level planning - handles building world state and choosing goal
RETURNS: Plan (action sequence) or nil

LINE 146: Build world state
  PZNS_GOAPWorldState.buildWorldState(npcSurvivor, { heavyScan = false })
  
  Takes: NPC and options
  Returns: State table of NPC's current situation
  Example: { hasWeaponEquipped=false, hasAmmo=true, ... }
  
  heavyScan = false:
    Do quick scan (performance)
    If true: thorough scan (slower but accurate)

LINE 147-150: Validation
  if not ws then
    return nil (failed to get state)
]]

	local desired = nil
	local usedActions = actionList or actions

--[[
LINE 151: Initialize desired state variable
  desired = nil (will be set based on goalOrDesired parameter)

LINE 152: Choose actions
  usedActions = actionList or actions
  If custom actionList provided, use it
  Otherwise use global actions table
  (Note: This line doesn't affect usage, bug?)
]]

	-- Resolve nil => auto-select best goal module
	if not goalOrDesired then
		local selected = M.selectBest(npcSurvivor)
		if not selected then
			print("PZNS_GOAPPlanner: no valid goal found for NPC")
			return nil
		end
		if type(selected.getDesiredState) ~= "function" then
			print("PZNS_GOAPPlanner: selected goal missing getDesiredState()")
			return nil
		end
		local ok, ds = pcall(selected.getDesiredState, npcSurvivor)
		if not ok or type(ds) ~= "table" then
			print("PZNS_GOAPPlanner: selected goal.getDesiredState() failed or returned non-table")
			return nil
		end
		desired = ds

--[[
LINE 154-162: CASE 1 - No goal specified, auto-select

if not goalOrDesired then
  → User called planForNPC(npc, nil) or planForNPC(npc)
  → No goal provided, pick best automatically

LINE 155: selected = M.selectBest(npcSurvivor)
  → Find the goal with highest priority for this NPC

LINE 156-158: Validate
  → Goal must exist
  → Goal must have getDesiredState function

LINE 159: pcall(selected.getDesiredState, npcSurvivor)
  → pcall = "protected call" (error handling)
  → Call the goal's getDesiredState function
  → If error: ok=false, ds=error message
  → If success: ok=true, ds=returned value

LINE 160: Validate result
  → Must be a table

LINE 162: desired = ds
  → Got the desired state from goal
  → Example: { isTargetDead = true }
]]

	elseif type(goalOrDesired) == "table" and type(goalOrDesired.getDesiredState) == "function" then
		local ok, ds = pcall(goalOrDesired.getDesiredState, npcSurvivor)
		if not ok or type(ds) ~= "table" then
			print("PZNS_GOAPPlanner: provided goal module failed getDesiredState()")
			return nil
		end
		desired = ds

--[[
LINE 163-168: CASE 2 - Goal module provided

elseif type(goalOrDesired) == "table" and
       type(goalOrDesired.getDesiredState) == "function" then
  
  → goalOrDesired is a table (potential goal module)
  → AND it has getDesiredState function
  → So treat it as a goal module

LINE 164-165: Same as Case 1
  → Call getDesiredState with error handling

LINE 166-168: Validate and store
  → Same validation
  → Store result in desired

USAGE EXAMPLE:
  local killGoal = require("killPlayer_Goal")
  planForNPC(npc, killGoal)  ← Pass goal module directly
]]

	else
		desired = goalOrDesired

--[[
LINE 169-170: CASE 3 - Direct state provided

else
  → goalOrDesired is neither nil nor a goal module
  → Treat it as already being the desired state table

desired = goalOrDesired
  → Just use it directly
  → Example: desired = { isTargetDead = true, hasWeapon = true }

USAGE EXAMPLE:
  planForNPC(npc, { isTargetDead = true })  ← Direct state
]]

	end

	-- debug: list desired keys
	for k, v in pairs(desired) do
		print("PZNS_GOAPPlanner: desired ->", k, v)
	end

--[[
LINE 171-174: Debug output

for k, v in pairs(desired) do
  → Loop through desired state predicates

print("PZNS_GOAPPlanner: desired ->", k, v)
  → Print each desired predicate
  → Output example:
    PZNS_GOAPPlanner: desired -> isTargetDead true
    PZNS_GOAPPlanner: desired -> hasWeapon true
]]

	return PZNS_GOAPPlanner.plan(ws, desired, usedActions)
end

--[[
LINE 175: Call A* planner

return PZNS_GOAPPlanner.plan(ws, desired, usedActions)

Arguments:
  ws = world state (current situation)
  desired = desired state (goal)
  usedActions = actions to choose from (default: global actions)

Returns:
  Plan array or nil

FINAL CALL:
  plan(worldState, goal, actions)
    → Uses A* to find sequence
    → Returns [Action1, Action2, ...]
]]

return PZNS_GOAPPlanner

--[[
LINE 176: Export module

return PZNS_GOAPPlanner

Makes all functions available to other files:
  planner.plan()
  planner.planForNPC()
  planner.selectBest()
  planner.getGoals()
  planner.geValidGoals()
]]
