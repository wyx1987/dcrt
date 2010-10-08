-- dcrt.lua
-- DCRT V3
-- Author: CN5-Ã·∂˚÷Æ ÷-Mizzle

local assert, getmetatable, setmetatable, type, print, time, pairs, ipairs, pcall = assert, getmetatable, setmetatable, type, print, time, pairs, ipairs, pcall
local table, string = table, string

local dcrt = CreateFrame("Frame", "DCRTFrame")

-- Get a new copy of dcrt by call DCRT().
function DCRT()
	local instance = {}
	setmetatable(instance, {
		__index = dcrt
	})
	return instance
end

local EVENTS = DCRTEvents()
local ERRORS = DCRTErrors()
local utils = DCRTUtils()
local config = DCRTConfig()
local db
local registeredEvents = {}

local addons = {}
local raids = {}

-- Initialize for events.
dcrt:SetScript("OnEvent", function(self, event, ...)
	self:FireEvent(event, ...)
	self:OnEvent(event, ...)
end)

-- Register events used by dcrt core.

do
	local function RegisterEvent(event)
		if not registeredEvents[event] then
			dcrt:RegisterEvent(event)
			registeredEvents[event] = 1
		else
			registeredEvents[event] = registeredEvents[event] + 1
		end
	end
	
	RegisterEvent("VARIABLES_LOADED")
end

-- Addon
local Addon = {}

function Addon:RegisterEvent(event)
	assert(type(event) == "string", "Event name must be string.")
	
	if self.events[event] then
		return
	end
	
	if not string.find(event, "DCRT") then
		if not registeredEvents[event] then
			dcrt:RegisterEvent(event)
			registeredEvents[event] = 1
		else
			registeredEvents[event] = registeredEvents[event] + 1
		end
	end
	
	if not self.events then
		self.events = {}
	end
		
	self.events[event] = true
end

function Addon:UnRegisterEvent(event)
	assert(type(event) == "string", "Event name must be string.")
	
	if not self.events[event] then
		return
	end
	
	if not string.find(event, "DCRT") then
		if registeredEvents[event] == 1 then
			registeredEvents[event] = nil
			dcrt:UnregisterEvent(event)
		else
			registeredEvents[event] = registeredEvents[event] - 1
		end
	end
	
	self.events[event] = nil
end

-- DKP
local DKP = {}


-- Member
local Member = {}

function Member:GetName()
	return self.name
end

function Member:GetClass()
	return self.class
end

function Member:GetScore(system)
	return self.score
end

-- Event
local Event = {}

-- Item
local Item = {}

function Item:GetName()
	return GetItemInfo(self.link)
end

function Item:GetLink()
	return self.link
end

function Item:GetLooter()
	return self.looter
end

function Item:SetLooter(looter)
	self.looter = looter
end

function Item:GetCost()
	return self.cast
end

function Item:SetCast(cast)
	self.cast = cast
end

-- Raid
local Raid = {}

function Raid:GetName()
	return self.name
end

function Raid:GetStartTime()
	return self.startTime
end

function Raid:GetFinishTime()
	return self.finishTime
end

function Raid:GetCreationTime()
	return self.creationTime
end

function Raid:Start()
	if utils.IsInRaid() then
		if not self.startTime then
			self.startTime = time()
			self.started = true
		else
			dcrt:FireEvent(EVENTS.ERROR, ERRORS.RAID_STARTED)
		end
	else
		dcrt:FireEvent(EVENTS.ERROR, ERRORS.NOT_IN_RAID)
	end
end

function Raid:Pause()
	if self.startTime then
		self.pause = true
	else
		dcrt:FireEvent(EVENTS.ERROR, ERRORS.RAID_NOT_START)
	end
end

function Raid:Resume()
	if self.startTime then
		self.pause = nil
	else
		dcrt:FireEvent(EVENTS.ERROR, ERRORS.RAID_NOT_START)
	end
end

function Raid:Finish()
	if self.startTime then
		self.finished = true
		self.finishTime = time()
	else
		dcrt:FireEvent(EVENTS.ERROR, ERRORS.RAID_NOT_START)
	end
end

function Raid:NewEvent()
	
end

function Raid:RemoveEvent(event)
end

function Raid:NewItem()
	if self.startTime then
		local item = {}
		setmetatable(item, {
			__index = Item
		})
		if not GetItemInfo(link) then
			GameTooltip:SetHyperlink(link) 
		end
		item.link = link
		return item
	else
		dcrt:FireEvent(EVENTS.ERROR, ERRORS.RAID_NOT_START)
	end
end

function Raid:RemoveItem(item)
	for k, v in ipairs(self.items) do
		if v == item then
			table.remove(self.items, k)
			break
		end
	end
end

function Raid:Export()
	
end

-- DCRT

function dcrt:NewAddon(name)
	local addon = {
		events = {}
	}
	addon.name = name
	setmetatable(addon, {
		__index = Addon
	})
	table.insert(addons, addon)
	return addon
end

function dcrt:FireEvent(event, ...)
	assert(type(event) == "string", "Event name must be string.")
	for _, addon in ipairs(addons) do
		if type(addon.OnEvent) == "function" and addon.events[event] then
			local res, err = pcall(addon.OnEvent, addon, event, ...)
			if not res then
				self:FireEvent(EVENTS.ERROR, ERRORS.RUNTIME_ERROR, err)
			end
		end
	end
end

function dcrt:OnEvent(event, ...)
	if event == "VARIABLES_LOADED" then
		if not DCRT3DB then
			DCRT3DB = {}
		end
		
		local realm = GetRealmName()
		if not DCRT3DB[realm] then
			DCRT3DB[realm] = {
				config = config,
				raids = raids
			}
		end
		
		db = DCRT3DB[realm]
		config = db.config
		raids = db.raids
	end
end

function dcrt:NewRaid(name)
	assert(type(name) == "string", "Raid name must be string.")
	if raids[name] then
		self:FireEvent(EVENTS.ERROR, ERRORS.DUPLICATE_RAID_NAME)
		return
	end
	if utils.IsInRaid() then
		local raid = {
			items = {},
			events = {},
			members = {}
		}
		setmetatable(raid, {
			__index = Raid,
			__eq = function(raid1, raid2)
				if raid1.name and raid2.name then
					return raid1.name == raid2.name
				end
				return false
			end
		})
		raid.name = name
		raid.creationTime = time()
		table.insert(raids, raid)
	else
		dcrt:FireEvent(EVENTS.ERROR, ERRORS.NOT_IN_RAID)
	end
	return raid
end

function dcrt:RemoveRaid(raid)
	for k, v in pairs(raids) do
		if raid == v then
			table.remove(raids, k)
			break
		end
	end
end
