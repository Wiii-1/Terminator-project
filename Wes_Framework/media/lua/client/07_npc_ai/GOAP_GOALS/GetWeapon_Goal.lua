local Goal = require("07_npc_ai/PZNS_Goal")

local GetWeapon_Goal = {}
GetWeapon_Goal.name = "GetWeapon_Goal"

setmetatable(GetWeapon_Goal, { __index = Goal })

function GetWeapon_Goal.isValid(ws)
	return ws.hasWeapon == false
end

function GetWeapon_Goal.getDesiredState()
	return { isWeaponEquipped = true }
end

function GetWeapon_Goal.priority()
	return 20
end

return GetWeapon_Goal

