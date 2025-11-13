--- Cows: The code here is mostly based on "SuperSurvivorPVPButton.lua"

require "ISUI/ISLayoutManager";
local ThePVPButton = ISButton:derive("ThePVPButton");
local PZNS_CombatUtils = require("02_mod_utils/PZNS_CombatUtils");

--- Cows: Creates the Toggle button to enable local/client-only players pvp.
function PZNS_CreatePVPButton()
    -- Guard: ensure local player exists before creating UI (avoid creating UI in main menu)
    if getSpecificPlayer(0) == nil then
        return;
    end

    PVPTextureOn = getTexture("media/textures/PVPOn.png");
    PVPTextureOff = getTexture("media/textures/PVPOff.png");

    PVPButton = ThePVPButton:new(
        getCore():getScreenWidth() - 100, getCore():getScreenHeight() - 50, 25, 25, "", nil,
        PZNS_CombatUtils.PZNS_TogglePvP
    );
    PVPButton:setImage(PVPTextureOff);
    PVPButton:setVisible(true);
    PVPButton:setEnable(true);
    -- protect UI creation from throwing errors and log registration for diagnostics
    pcall(function()
        print("[PZNS_UI_LOG] PZNS_PVPButton:addToUIManager playerExists=" .. tostring(getSpecificPlayer(0) ~= nil))
        if debug and debug.traceback then
            print("[PZNS_UI_LOG] stack: " .. tostring(debug.traceback()))
        end
        PVPButton:addToUIManager();
    end)
end
