-- error.lua
-- Author: CN5-提尔之手-Mizzle
-- Default error handler for DCRT3

local dcrt = DCRT()
addon = dcrt:NewAddon("Error")
local events = DCRTEvents()
local errors = DCRTErrors()

addon:RegisterEvent(events.ERROR)

local l = {}

if GetLocale() == "zhCN" then
	l[errors.RUNTIME_ERROR] = "运行时错误。"
	l[errors.DUPLICATE_RAID_NAME] = "重复的活动名称。"
	l[errors.NOT_IN_RAID] = "不在团队中。"
	l[errors.RAID_STARTED] = "活动已开始。"
	l[errors.RAID_FINISHED] = "活动已结束。"
	l[errors.RAID_NOT_START] = "活动未开始。"
	l[errors.RAID_NOT_FINISH] = "活动未结束。"
end

function addon:OnEvent(event, err)
	if event == events.ERROR then
		print(l[err])
	end
end