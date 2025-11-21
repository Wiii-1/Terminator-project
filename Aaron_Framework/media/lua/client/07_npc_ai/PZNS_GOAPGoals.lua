local PZNS_GOAPGoals = {}

-- ============ GOAL: Kill Player ============
-- Objective: Eliminate the player
-- Preconditions: Must see player, must have ammo, must be able to aim
PZNS_GOAPGoals.KillPlayer = {
	isTargetVisible = true,
	isWeaponEquipped = true,
	isAmmoLow = false,
	targetAlive = false, -- TODO: Add in worldState
}

-- ============ GOAL: Find Player ============
-- Objective: Locate and track the player
-- Preconditions: Player exists but not visible
-- Effects: Update memory with player location
PZNS_GOAPGoals.FindPlayer = {
	isTargetVisible = false,
	isTargetInFollowRange = true,
	targetFound = true, -- TODO: Add in worldState
}

-- ============ GOAL: Gather Resources ============
-- Objective: Collect ammo, weapons, and supplies
-- Preconditions: Low on resources or idle
-- Effects: Inventory improved, ammo increased
PZNS_GOAPGoals.GatherResources = {
	isAmmoLow = false,
	isWeaponEquipped = true,
	hasBackupWeapon = true,
	resourcesGathered = true, -- TODO: Add in worldState
}

-- ============ GOAL: Recuperate ============
-- Objective: Recover health and get to safety
-- Preconditions: Health critical or under heavy fire
-- Effects: Health restored,  threats eliminated
PZNS_GOAPGoals.Recuperate = {
	isHealthLow = false,
	threatLevel = 0, -- TODO: Add in worldState
	healthRestored = true, -- TODO: Add in worldState
}

-- ============ GOAL: Survive ============
-- Objective: Stay alive at all costs
-- Preconditions: Health critical or outnumbered
-- Effects: Just exist lmao
PZNS_GOAPGoals.Survive = {
	isHealthLow = false, -- Health restored to safe level
	isAlive = true, -- Still alive  TODO: Add in worldState
}

-- Goal Selection Logic
function PZNS_GOAPGoals.SelectGoal(worldState)
	-- Priority order:
	-- 1. Survive if critical
	if worldState.isHealthLow then
		return PZNS_GOAPGoals.Recuperate, "Recuperate"
	end

	-- 2. Kill if target visible and in range
	if worldState.isTargetVisible and worldState.isWeaponEquipped then
		if worldState.isAmmoLow == false then
			return PZNS_GOAPGoals.KillPlayer, "KillPlayer"
		end
	end

	-- 3. Find if target known but not visible
	if not worldState.targetFound and not worldState.isTargetVisible then
		return PZNS_GOAPGoals.FindPlayer, "FindPlayer"
	end

	-- 4. Gather resources if running low
	if worldState.isAmmoLow or not worldState.isWeaponEquipped then
		return PZNS_GOAPGoals.GatherResources, "GatherResources"
	end

	-- Default: Survive
	return PZNS_GOAPGoals.Survive, "Survive"
end
