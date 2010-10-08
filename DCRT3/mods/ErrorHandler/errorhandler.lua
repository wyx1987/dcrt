-- error.lua
-- Author: CN5-提尔之手-Mizzle
-- Default error handler for DCRT3

local dcrt = DCRT()
addon = dcrt:NewAddon("ErrorHandler")
local events = DCRTEvents()
local errors = DCRTErrors()

addon:RegisterEvent(events.ERROR)

function addon:OnEvent(event, err)
	if event == events.ERROR then
		print(err)
	end
end