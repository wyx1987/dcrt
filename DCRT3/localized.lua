-- events.lua
-- DCRT V3 本地化，暂时仅提供简体中文.
-- Author: CN5-提尔之手-Mizzle

local localized

if GetLocale() == "zhCN" then
	localized = {
		-- for errors.
		RUNTIME_ERROR = "运行时错误。",
		DUPLICATE_RAID_NAME = "重复的活动名称。",
		NOT_IN_RAID = "不在团队中。",
		RAID_STARTED = "活动已开始。",
		RAID_FINISHED = "活动已结束。",
		RAID_NOT_START = "活动未开始。",
		RAID_NOT_FINISH = "活动未结束。",
	}
end

function DCRTLocale()
	return localized
end