-- messagehandler.lua
-- DCRT V3 默认消息显示.
-- Author: CN5-提尔之手-Mizzle

local dcrt = DCRT()
local addon = dcrt:NewAddon("MessageHandler")
local events = DCRTEvents()
print(11)

local prefix = ""

if GetLocale() == "zhCN" then
	prefix = "DCRT消息："
end

addon:RegisterEvent(events.SHOW_MESSAGE)

function addon:OnEvent(event, _type, msg)
	print(event, _type, msg)
	if event == events.SHOW_MESSAGE then
		local message = "|c00ffff00" .. prefix .. "|r"
		if type == "error" then
			message = message .. "|c00ff0000" .. msg .. "|r"
		elseif type == "info" then
			message = message .. "|c0000ff00" .. msg .. "|r"
		end
		print(message)
	end
end