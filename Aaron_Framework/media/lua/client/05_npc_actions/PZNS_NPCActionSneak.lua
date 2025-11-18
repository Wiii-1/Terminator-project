--[[
    PZNS_NPCActionSneak.lua - Reusable Sneak Action for NPCs
    
    Enables any NPC to move quietly and avoid detection
    Used for stealth-based approaches or evasion
]]

local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
local PZNS_GeneralAI = require("07_npc_ai/PZNS_GeneralAI")

local PZNS_NPCActionSneak = {}

---Execute Sneak Action - Move quietly to avoid detection
---@param npcSurvivor any
---@param targetSquare any Optional target square to sneak toward
---@return boolean success
function PZNS_NPCActionSneak.execute(npcSurvivor, targetSquare)
	if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
		return false
	end

	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject

	-- Set sneak mode for the NPC
	if npcIsoPlayer:getSneakMode() then
		npcIsoPlayer:setSneakMode(true)
	end

	-- If target square provided, move toward it
	if targetSquare then
		PZNS_GeneralAI.PZNS_WalkToTargetSquare(npcSurvivor, targetSquare)
	else
		-- Otherwise, move to job square while sneaking
		PZNS_GeneralAI.PZNS_WalkToJobSquare(npcSurvivor)
	end

	return true
end

---Exit sneak mode
---@param npcSurvivor any
---@return boolean success
function PZNS_NPCActionSneak.exitSneak(npcSurvivor)
	if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
		return false
	end

	local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject

	if npcIsoPlayer:getSneakMode() then
		npcIsoPlayer:setSneakMode(false)
	end

	return true
end

---Get action metadata
---@return table metadata
function PZNS_NPCActionSneak.getMetadata()
	return {
		name = "Sneak",
		cost = 2.0,
		duration = 1.2,
		description = "Move quietly to avoid detection",
	}
end

return PZNS_NPCActionSneak

