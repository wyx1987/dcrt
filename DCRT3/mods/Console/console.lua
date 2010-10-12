-- console.lua
-- DCRT V3 控制台.
-- Author: CN5-提尔之手-Mizzle

local string, table = string, table

local dcrt = DCRT()
local console = dcrt:NewAddon("console")
local locale = DCRT_ConsoleLocale()

console:RegisterCommand("dcrt")

local function ParseArgs(args)
	local argTable = {}
	string.gsub(string.lower(args), "([^%s]+)", function(arg)
		table.insert(argTable, arg)
	end)
	return argTable
end

function console:OnCommand(cmd, ...)
	local argTable = ParseArgs(...)
	if cmd == "dcrt" then
		if argTable[1] == "raid" then
			if argTable[2] == "new" then
				
			else
				print(locale["RAID_USAGE"])
			end
		else
			print(locale["USAGE"])
		end
	end
end