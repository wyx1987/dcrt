-- utils.lua
-- DCRT V3 utils.
-- Author: CN5-提尔之手-Mizzle

local utils = {
	IsInRaid = function()
		return GetNumRaidMembers() ~= 0
	end
}

-- Get a new copy of utils.
function DCRTUtils()
	return utils
end
