-- errors.lua
-- DCRT V3 Errors.
-- Author: CN5-提尔之手-Mizzle

local errors = {
	RUNTIME_ERROR = 1,
	DUPLICATE_RAID_NAME = 2,
	NOT_IN_RAID = 3,
	RAID_STARTED = 4,
	RAID_FINISHED = 5,
	RAID_NOT_START = 6,
	RAID_NOT_FINISH = 7
}

-- Get a new copy of errors.
function DCRTErrors()
	return errors
end