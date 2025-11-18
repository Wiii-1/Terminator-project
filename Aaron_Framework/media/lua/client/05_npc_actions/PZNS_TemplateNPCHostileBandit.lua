local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager");

local npcSurvivorID = "PZNS_BanditTester";

--- Creates a hostile bandit NPC that will attack the player
--- This template demonstrates how to use isRaider = true to create a hostile NPC
---@param mpPlayerID any
function PZNS_SpawnBanditTester(mpPlayerID)
    local isNPCActive = PZNS_NPCsManager.getActiveNPCBySurvivorID(npcSurvivorID);
    local defaultID = 0;
    
    -- Check if the NPC is already active before continuing.
    if (isNPCActive == nil) then
        local playerSurvivor = getSpecificPlayer(defaultID);
        local npcSurvivor = PZNS_NPCsManager.createNPCSurvivor(
            npcSurvivorID,             -- Unique Identifier for the npcSurvivor so that it can be managed.
            false,                     -- isFemale
            "Bandit",                  -- Surname
            "Hostile",                 -- Forename
            playerSurvivor:getSquare() -- Square to spawn at
        );
        
        if (npcSurvivor ~= nil) then
            -- === MAKE NPC HOSTILE ===
            -- These two lines are the KEY to creating a hostile NPC:
            npcSurvivor.isRaider = true;    -- Mark as raider/hostile (enables hostility checks)
            npcSurvivor.affection = 0;      -- Set affection to 0 (ensures always hostile, > 0 would make friendly)
            
            -- Visual indicator: Red name text (same as raiders)
            npcSurvivor.textObject:setDefaultColors(225, 0, 0, 0.8);
            npcSurvivor.textObject:ReadString("Hostile Bandit");
            
            -- Do not save between game sessions (like raiders)
            npcSurvivor.canSaveData = false;
            
            -- === SKILLS & PERKS ===
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Strength", 4);
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Fitness", 4);
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Aiming", 3);
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Reloading", 3);
            
            -- === OUTFIT (bandit/raider style) ===
            -- Bandana mask (identifies as bandit)
            PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Hat_BandanaMask");
            PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Shirt_HawaiianRed");
            PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Trousers_Denim");
            PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Socks");
            PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Shoes_ArmyBoots");
            
            -- === WEAPON (50/50 gun or melee) ===
            local spawnWithGun = ZombRand(0, 100) > 50;
            if (spawnWithGun) then
                -- Spawn with pistol
                PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, "Base.Pistol");
                PZNS_UtilsNPCs.PZNS_SetLoadedGun(npcSurvivor);
                PZNS_UtilsNPCs.PZNS_AddItemToInventoryNPCSurvivor(npcSurvivor, "Base.9mmClip");
                PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(npcSurvivor, "Base.Bullets9mm", 20);
            else
                -- Spawn with melee weapon
                PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, "Base.BaseballBat");
            end
            
            -- === SET JOB (Wander In Cell will make them patrol and hunt) ===
            -- The "Wander In Cell" job combined with isRaider=true will make the NPC:
            -- 1. Detect the player
            -- 2. Aim at the player
            -- 3. Attack on sight
            PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, "Wander In Cell");
            
            -- Save NPC data
            PZNS_UtilsDataNPCs.PZNS_SaveNPCData(npcSurvivorID, npcSurvivor);
        end
    end
end

-- Cleanup function to remove the hostile NPC
function PZNS_DeleteBanditTester(mpPlayerID)
    local npcSurvivor = PZNS_NPCsManager.getActiveNPCBySurvivorID(npcSurvivorID);
    if (npcSurvivor ~= nil) then
        PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor);
        PZNS_NPCsManager.deleteActiveNPCBySurvivorID(npcSurvivorID);
    end
end
