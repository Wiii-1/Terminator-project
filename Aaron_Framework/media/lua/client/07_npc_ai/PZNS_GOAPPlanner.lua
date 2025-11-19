
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils")

local PZNS_GOAPPlanner = {}

local actions = {
    require("05_npc_actions/PZNS_GOAPGunMagazine"),
    require("05_npc_actions/PZNS_GOAPHuntPlayer"),
    require("05_npc_actions/PZNS_GOAPPickUpWeapon"),
    require("05_npc_actions/PZNS_GOAPRunTo"),
    require("05_npc_actions/PZNS_GOAPScavenge"),
    require("05_npc_actions/PZNS_GOAPSwitchWeapon"),
    require("05_npc_actions/PZNS_GOAPWalkTo"),
    require("05_npc_actions/PZNS_GOAPWeaponAiming"),
    require("05_npc_actions/PZNS_GOAPWeaponAttack"),    
    require("05_npc_actions/PZNS_GOAPWeaponEquip"),
    require("05_npc_actions/PZNS_GOAPWeaponReload"),
}

local function copystate()
end

local function meetsPreconditions()
end

local function applyEffects()
end

local function stateHash()
end

local function heuristic()
end

function PZNS_GOAPPlanner.plan(worldState, goal, actions)
end

return PZNS_GOAPPlanner;
