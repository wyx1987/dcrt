-- error.lua
-- Author: CN5-提尔之手-Mizzle
-- Default error handler for DCRT3

local dcrt = DCRT()
addon = dcrt:NewAddon("ErrorHandler")
local events = DCRTEvents()
local errors = DCRTErrors()

local locale = GetLocale()

addon:RegisterEvent(events.ERROR)

function addon:OnEvent(event, err, ...)
	if event == events.ERROR then
		local message = ""
		if err == errors.RUNTIME_ERROR then
			message = err .. (...)
		end
		addon:ShowMessage("error", message)
	end
end