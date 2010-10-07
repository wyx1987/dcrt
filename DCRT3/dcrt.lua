-- dcrt.lua
-- DCRT V3
-- Author: CN5-Ìá¶ûÖ®ÊÖ-Mizzle

local assert, getmetatable, setmetatable, type, print, time, pairs, ipairs, pcall = assert, getmetatable, setmetatable, type, print, time, pairs, ipairs, pcall
local table, string = table, string

local dcrt = CreateFrame("Frame", "DCRT")

-- Get a new copy of dcrt by call DCRT().
getmetatable(DCRT).__call = function()
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
local timers = {}
local raids = {}

-- Initialize for timers.
local lastcall = time()
dcrt:SetScript("OnUpdate", function()
	local now = time()
	if now - lastcall > 0 then
		for _, timer in ipairs(timers) do
			if timer.enabled and now - timer.lastcall >= timer.initval then
				local res, err = pcall(timer.handler)
				if not res then
					dcrt:FireEvent(EVENTS.ERROR, ERRORS.RUNTIME_ERROR, err)
				end
				timer.lastcall = now
			end
		end
		lastcall = now
	end
end)

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
local Addon = {
	__index = Addon
}

function Addon:RegisterEvent(event)
	assert(type(event) == "string", "Event name must be string.")
	assert(type(handle) == "function", "Handle must be function.")
	
	if self.events[event] then
		return
	end
	
	if not string.find(event, "DCRT") and not registeredEvents[event] then
		dcrt:RegisterEvent(event)
		registeredEvents[event] = 1
	else
		registeredEvents[event] = registeredEvents[event] + 1
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
	
	if not string.find(event, "DCRT") and registeredEvents[event] == 1 then
		registeredEvents[event] = nil
		dcrt:UnregisterEvent(event)
	else
		registeredEvents[event] = registeredEvents[event] - 1
	end
	
	self.events[event] = nil
end

-- Timer
local Timer = {
	__index = Timer
}

function Timer:Enable()
	self.enable = true
end

function Timer:Disable()
	self.enable = nil
end

function Timer:SetInitval(initval)
	assert(type(initval) == "number", "Initval must be number.")
	self.initval = initval
end

function Timer:SetHandler(handler)
	assert(type(handler) == "function", "Handler must be function.")
	self.handler = handler
end

-- DKP
local DKP = {
	__index = DKP
}


-- Member
local Member = {
	__index = Member
}

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
local Event = {
	__index = Event
}

-- Item
local Item = {
	__index = Item
}

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
local Raid = {
	__index = Raid,
	__eq = function(raid1, raid2)
		if raid1.name and raid2.name then
			return raid1.name == raid2.name
		end
		return false
	end
}

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
	if not startTime then
		self.startTime = time()
		self.started = true
	end
end

function Raid:Pause()
	self.pause = true
end

function Raid:Resume()
	self.pause = nil
end

function Raid:Finish()
	self.finished = true
	self.finishTime = time()
end

function Raid:NewEvent()
end

function Raid:RemoveEvent(event)
end

function Raid:NewItem()
	local item = {}
	setmetatable(item, Item)
	if not GetItemInfo(link) then
		GameTooltip:SetHyperlink(link) 
	end
	item.link = link
	return item
end

function Raid:RemoveItem(item)
end

function Raid:GetTimer()
	return self.timer
end

-- DCRT
function dcrt:NewTimer(initval, handler)
	if initval then
		assert(type(initval) == "number", "Initval must be number.")
	end
	
	if handler then
		assert(type(handler) == "function", "Handler must be function.")
	end
	
	local timer = {
		initval = initval or 1
	}
	setmetatable(timer, Timer)
	table.insert(self.timers, timer)
	return timer
end

function dcrt:RemoveTimer(timer)
	for k, v in ipairs(self.timers) do
		if v == timer then
			table.remove(self.timers, k)
			break
		end
	end
end

function dcrt:NewAddon(name)
	local addon = {
		events = {}
	}
	addon.name = name
	setmetatable(addon, Addon)
	table.insert(addons, addon)
	return addon
end

function dcrt:FireEvent(event, ...)
	assert(type(event) == "string", "Event name must be string.")
	for _, addon in ipairs(addons) do
		if type(addon.OnEvent) == "function" and addon.events[event] then
			local res, err = pcall(addon.OnEvent, event, ...)
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
				config = config
			}
		end
		
		db = DCRT3DB[realm]
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
		setmetatable(raid, Raid)
		raid.name = name
		raid.creationTime = time()
		raid.timer = dcrt:NewTimer()
		table.insert(raids, raid)
	else
		dcrt:FireEvent(EVENTS.ERROR, ERRORS.NOT_IN_RAID)
	end
	return raid
end

function dcrt:RemoveRaid(raid)
	dcrt:RemoveTimer(raid.timer)
	for k, v in pairs(raids) do
		if raid == v then
			table.remove(raids, k)
			break
		end
	end
end
