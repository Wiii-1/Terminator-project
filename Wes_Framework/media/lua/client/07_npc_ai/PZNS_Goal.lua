local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

local PZNS_Goal = {}

function PZNS_Goal.isValid()
    return false
end

function PZNS_Goal.priority()
    return 0
end

function PZNS_Goal.getDesiredState()
    return {}
end

return PZNS_Goal
