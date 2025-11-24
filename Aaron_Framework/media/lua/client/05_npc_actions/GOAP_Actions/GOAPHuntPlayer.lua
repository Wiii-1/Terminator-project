local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")
local PZNS_GOAPAction = require("05_npc_ai/PZNS_GOAP_Actions")

local GOAPHuntPlayer = {}
GOAPHuntPlayer.name = "GOAP_Hunt_Player"

setmetatable(GOAPHuntPlayer, { __index = PZNS_GOAPAction })

function GOAPHuntPlayer:isValid(npc, targetID)
	if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npc) then
		return false
	end
	local ws = PZNS_WorldUtils.BuildNPCWorldState(npc, { heavyScan = false })
	return not ws.isPlayerVisible
end

function GOAPHuntPlayer:cost(npc, targetID)
	return 7.0
end

function GOAPHuntPlayer:getPreconditions()
	return { isPlayerVisible = false }
end

function GOAPHuntPlayer:getEffects()
	return { hasReachedPlayer = true }
end

-- ============================================
-- GOAPHuntPlayer.perform() WITH DEBUG OUTPUT
-- ============================================

local DEBUG_HUNT = true -- Toggle debug output

function GOAPHuntPlayer.perform(npcSurvivor)
	-- ========== DEBUG: FUNCTION START ==========
	if DEBUG_HUNT then
		print("\n[HUNT] ===== HUNT PLAYER PERFORM START =====")
		print("[HUNT] NPC: " .. (npcSurvivor.name or "unknown"))
	end
end

-- ============================================
-- HELPER: Debug Hunt Target Location
-- ============================================

function GOAPHuntPlayer:debugTargetLocation(npcSurvivor)
	if DEBUG_HUNT then
		print("\n[HUNT DEBUG] ===== TARGET LOCATION INFO =====")
	end

	if not npcSurvivor.lastKnownPlayerX then
		if DEBUG_HUNT then
			print("[HUNT DEBUG] ✗ No stored target location")
		end
		return
	end

	if DEBUG_HUNT then
		print("[HUNT DEBUG] Stored target location:")
		print("[HUNT DEBUG] X: " .. npcSurvivor.lastKnownPlayerX)
		print("[HUNT DEBUG] Y: " .. npcSurvivor.lastKnownPlayerY)
		print("[HUNT DEBUG] Z: " .. npcSurvivor.lastKnownPlayerZ)

		if npcSurvivor.lastKnownPlayer then
			print("[HUNT DEBUG] Target player: " .. (npcSurvivor.lastKnownPlayer:getUsername() or "unknown"))
		else
			print("[HUNT DEBUG] Target player: nil")
		end

		-- Calculate distance from NPC to target
		local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
		local npx = npcIsoPlayer:getX()
		local npy = npcIsoPlayer:getY()

		local dx = npx - npcSurvivor.lastKnownPlayerX
		local dy = npy - npcSurvivor.lastKnownPlayerY
		local distance = math.sqrt(dx * dx + dy * dy)

		print("[HUNT DEBUG] Distance from NPC: " .. string.format("%.2f", distance) .. " tiles")
		print("[HUNT DEBUG] =========================================\n")
	end
end

-- ============================================
-- HELPER: Debug Movement Action Queuing
-- ============================================

function GOAPHuntPlayer:debugMovementActions(npcSurvivor)
	if DEBUG_HUNT then
		print("\n[HUNT DEBUG] ===== MOVEMENT ACTIONS INFO =====")
	end

	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
	local actionQueue = ISTimedActionQueue.getTimedActionQueue(npcIsoPlayer)
	local actionCount = 0

	if actionQueue and actionQueue.queue then
		actionCount = #actionQueue.queue
	end

	if DEBUG_HUNT then
		print("[HUNT DEBUG] Actions queued: " .. actionCount)

		if actionQueue and actionQueue.queue then
			for i, action in ipairs(actionQueue.queue) do
				print(
					"[HUNT DEBUG] ["
						.. i
						.. "] "
						.. (action.Type or "unknown")
						.. " - "
						.. (action.description or "no desc")
				)
			end
		end

		print("[HUNT DEBUG] =========================================\n")
	end
end

-- ============================================
-- OUTPUT EXAMPLES
-- ============================================

--[[

EXAMPLE OUTPUT 1: Starting Hunt
================================
[HUNT] ===== HUNT PLAYER PERFORM START =====
[HUNT] NPC: Chris
[HUNT] Validating NPC survivor...
[HUNT] ✓ NPC survivor valid
[HUNT] Resolving target player...
[HUNT] Target ID: string:Player0
[HUNT] Target ID is Player string, getting Player0
[HUNT] ✓ Target player found: Player
[HUNT] Resolving target location...
[HUNT] Target player exists, checking last known location
[HUNT] ✓ Using current player location: (1000, 2000, 0)
[HUNT] Stored target location in NPC survivor
[HUNT] ✓ Valid target location found
[HUNT] Calculating distance to target...
[HUNT] NPC position: (950, 1950, 0)
[HUNT] Target position: (1000, 2000, 0)
[HUNT] Distance to target: 70.71 tiles
[HUNT] Determining movement action...
[HUNT] Distance > 5, executing: PZNS_RunTo (last known: 1000, 2000, 0)
[HUNT] Checking if hunt is complete (distance <= 2)...
[HUNT] Still hunting... Distance: 70.71 tiles
[HUNT] ===== HUNT PLAYER PERFORM END (IN PROGRESS) =====


EXAMPLE OUTPUT 2: Hunt Complete
================================
[HUNT] ===== HUNT PLAYER PERFORM START =====
[HUNT] NPC: Chris
[HUNT] Validating NPC survivor...
[HUNT] ✓ NPC survivor valid
[HUNT] Resolving target player...
[HUNT] ✓ Target player found: Player
[HUNT] Resolving target location...
[HUNT] Target player exists, checking last known location
[HUNT] ✓ Using current player location: (1000, 2000, 0)
[HUNT] Stored target location in NPC survivor
[HUNT] ✓ Valid target location found
[HUNT] Calculating distance to target...
[HUNT] NPC position: (1001, 2000, 0)
[HUNT] Target position: (1000, 2000, 0)
[HUNT] Distance to target: 1.00 tiles
[HUNT] Determining movement action...
[HUNT] Distance <= 5, executing: PZNS_WalkTo
[HUNT] Checking if hunt is complete (distance <= 2)...
[HUNT] ✓ TARGET REACHED!
[HUNT] Distance: 1.00 tiles
[HUNT] Clearing stored target location...
[HUNT] ✓ Location cleared, hunt complete!
[HUNT] ===== HUNT PLAYER PERFORM END (COMPLETE) =====


EXAMPLE OUTPUT 3: Using Last Known Location
=============================================
[HUNT] ===== HUNT PLAYER PERFORM START =====
[HUNT] Resolving target player...
[HUNT] ⚠️  Target player not found, using last known location
[HUNT] No target player, falling back to client player
[HUNT] ✓ Using client player LastKnownLocation: (500, 600, 0)
[HUNT] Valid target location found
[HUNT] Distance to target: 45.50 tiles
[HUNT] Distance > 5, executing: PZNS_RunTo
[HUNT] Still hunting... Distance: 45.50 tiles
[HUNT] ===== HUNT PLAYER PERFORM END (IN PROGRESS) =====

]]

-- ============================================
-- USAGE
-- ============================================

--[[
In your code:

-- Enable/disable debug
DEBUG_HUNT = true  -- or false

-- Call perform
GOAPHuntPlayer:perform(npcSurvivor)

-- Debug specific info
GOAPHuntPlayer:debugTargetLocation(npcSurvivor)
GOAPHuntPlayer:debugMovementActions(npcSurvivor)
]]
