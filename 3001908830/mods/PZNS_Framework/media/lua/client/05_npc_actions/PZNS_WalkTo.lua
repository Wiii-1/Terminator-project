local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");

--- Cows: Have the specified NPC move to the square specified by xyz coordinates.
---@param npcSurvivor any
---@param squareX any
---@param squareY any
---@param squareZ any
function PZNS_WalkToSquareXYZ(npcSurvivor, squareX, squareY, squareZ)
    if (PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) == false) then
        return;
    end
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject;
    local targetSquare = getCell():getGridSquare(
        squareX, -- GridSquareX
        squareY, -- GridSquareY
        squareZ  -- Floor level
    );

	if targetSquare ~= nil then
        npcIsoPlayer:NPCSetRunning(false);
        local walkAction = ISWalkToTimedAction:new(npcIsoPlayer, targetSquare);
        -- debug: report walk request and whether the action was added
        print("[PZNS_WalkTo] NPC id=" .. tostring(npcSurvivor.survivorID) .. " requesting walk to (" .. tostring(squareX) .. "," .. tostring(squareY) .. "," .. tostring(squareZ) .. ")")
        local added = PZNS_UtilsNPCs.PZNS_AddNPCActionToQueue(npcSurvivor, walkAction);
        print("[PZNS_WalkTo] add result for NPC id=" .. tostring(npcSurvivor.survivorID) .. ": " .. tostring(added))
        return added
	end
end

-- Return module table for require() callers
return { PZNS_WalkToSquareXYZ = PZNS_WalkToSquareXYZ }
