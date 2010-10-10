-- errors.lua
-- DCRT V3 Errors.
-- Author: CN5-提尔之手-Mizzle

local l = DCRTLocale()

local errors = {
	RUNTIME_ERROR = l.RUNTIME_ERROR,
	DUPLICATE_RAID_NAME = l.DUPLICATE_RAID_NAME,
	NOT_IN_RAID = l.NOT_IN_RAID,
	RAID_STARTED = l.RAID_STARTED,
	RAID_FINISHED = l.RAID_FINISHED,
	RAID_NOT_START = l.RAID_NOT_START,
	RAID_NOT_FINISH = l.RAID_NOT_FINISH
}

function DCRTErrors()
	return errors
end