PZNS_GOAPAction = require("07_npc_ai/PZNS_GOAPAction");

local GOAP_SwitchWeapon= {}
GOAP_SwitchWeapon.name = "GOAP_Switch_Weapon";

setmetatable(GOAP_SwitchWeapon, { __index = PZNS_GOAPAction });

function GOAP_SwitchWeapon.isValid() 
    return true
end

function GOAP_SwitchWeapon.get_Cost()
    return 1.0
end

function GOAP_SwitchWeapon.get_preconditions() 
    return {}
end


function GOAP_SwitchWeapon.get_effects() 
    return {}
end

function GOAP_SwitchWeapon.perform(npcSurvivor, delta) 
    return false
end

return GOAP_SwitchWeapon