local GOAP_Actions = {}

function GOAP_Actions.isValid()
	return true
end

function GOAP_Actions.get_Cost()
	return 10000
end

function GOAP_Actions.get_preconditions()
	return {}
end

function GOAP_Actions.get_effects()
	return {}
end

function GOAP_Actions.perform(npcSurvivor)
	return false
end

return GOAP_Actions
