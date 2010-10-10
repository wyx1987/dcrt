-- console.lua
-- DCRT V3 控制台.
-- Author: CN5-提尔之手-Mizzle

local string, table = string, table

local dcrt = DCRT()
local console = dcrt:NewAddon("console")
local locale = DCRT_ConsoleLocale()

console:RegisterCommand("dcrt")

local function Usage()
	print(locale["USAGE"])
	console:ShowMessage("info", locale["USAGE"])
end

local function ParseArgs(args)
	local argTable = {}
	string.gsub(string.lower(args), "([^%s]+)", function(arg)
		table.insert(argTable, arg)
	end)
end

function console:OnCommand(cmd, ...)
	local argTable = ParseArgs(...)
	if cmd == "dcrt" then
		print(argTable[1])
		if argTable[1] == "raid" then
			if argTable[2] == "new" then
				
			end
		else
			Usage()
		end
	end
end