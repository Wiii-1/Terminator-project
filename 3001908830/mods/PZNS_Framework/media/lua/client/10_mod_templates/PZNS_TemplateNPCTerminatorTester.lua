local PZNS_DebuggerUtils = require("02_mod_utils/PZNS_DebuggerUtils");
local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager");


local npcSurvivorID = "PZNS_TerminatorTester";

--- Spawn a Terminator next to the player for testing
---@param mpPlayerID any
function PZNS_SpawnTerminatorTester(mpPlayerID)
    local defaultID = 0;
    local playerID = "Player" .. tostring(defaultID);
    local playerSurvivor = getSpecificPlayer(defaultID);
    if not playerSurvivor then
        print("[PZNS_TemplateNPCTerminatorTester] No player found to spawn next to")
        return
    end

    local isNPCActive = PZNS_NPCsManager.getActiveNPCBySurvivorID(npcSurvivorID);
    local defaultID = 0;
    local playerID = "Player" .. tostring(defaultID);
    local playerGroupID = "Player" .. tostring(defaultID) .. "Group";
    local isGroupExists = PZNS_NPCGroupsManager.getGroupByID(playerGroupID);
    -- Cows: Check if the group exists before continuing, can be removed if NPC doesn't need or have a group.
    if (isGroupExists) then
        -- Cows: Check if the NPC is active before continuing.
        if (isNPCActive == nil) then
            local playerSurvivor = getSpecificPlayer(defaultID);
            local npcSurvivor = PZNS_NPCsManager.createNPCSurvivor(
                npcSurvivorID,             -- Unique Identifier for the npcSurvivor so that it can be managed.
                false,                     -- isFemale
                "Terminator",            -- Surname
                "The",                   -- Forename
                playerSurvivor:getSquare() -- Square to spawn at
            );
            --
            if (npcSurvivor ~= nil) then
                PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Strength", 5);
                PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Fitness", 5);
                PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Aiming", 5);
                PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Reloading", 5);
                PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Strength", 7);
                PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Sneak", 7);
                
                if (PZNS_DebuggerUtils.PZNS_IsModActive("redfield") == true) then
                    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.redfield");
                else
                    -- Cows: Else use vanilla assets
                    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Trousers_Denim");
                    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Shoes_ArmyBoots");
                    PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, "Base.BaseballBat");
                end
                PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, "Base.Shotgun");
                PZNS_UtilsNPCs.PZNS_SetLoadedGun(npcSurvivor);
                PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(npcSurvivor, "Base.ShotgunShells", 12);
                -- Cows: Instead of assigning a job and follow target, mark this NPC as a Terminator so the GOAP brain will control it.
                npcSurvivor.isTerminator = true;
                -- Cows: Group Assignment (optional)
                PZNS_NPCGroupsManager.addNPCToGroup(npcSurvivor, playerGroupID);
                PZNS_UtilsNPCs.PZNS_SetNPCGroupID(npcSurvivor, playerGroupID);

                PZNS_UtilsDataNPCs.PZNS_SaveNPCData(npcSurvivorID, npcSurvivor);
            end
        end
    end
end

--- Delete the TerminatorTester
---@param mpPlayerID any
function PZNS_DeleteTerminatorTester(mpPlayerID)
    local npcSurvivor = PZNS_NPCsManager.getActiveNPCBySurvivorID(npcSurvivorID);
    if (npcSurvivor == nil) then
        print("[PZNS_TemplateNPCTerminatorTester] No active TerminatorTester to delete")
        return
    end
    PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor);
    PZNS_NPCGroupsManager.removeNPCFromGroupBySurvivorID(npcSurvivor.groupID, npcSurvivorID);
    PZNS_NPCsManager.deleteActiveNPCBySurvivorID(npcSurvivorID);
    print("[PZNS_TemplateNPCTerminatorTester] Deleted TerminatorTester")
end
