-- events.lua
-- DCRT V3 Events.
-- Author: CN5-提尔之手-Mizzle

local events = {
	ERROR = "DCRT_ERROR",
	
	SHOW_MESSAGE = "DCRT_SHOW_MESSAGE",
	
	--Raid
	RAID_CREATE = "DCRT_RAID_CREATE",
	RAID_START = "DCRT_RAID_START",
	RAID_PAUSE = "DCRT_RAID_PAUSE",
	RAID_RESUME = "DCRT_RAID_RESUME",
	RAID_FINISH = "DCRT_RAID_FINISH"
}

function DCRTEvents()
	return events
end
