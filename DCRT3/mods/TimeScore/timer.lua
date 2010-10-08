-- Timer.lua
-- DCRT V3 计时器.
-- Author: CN5-提尔之手-Mizzle

local dcrt = DCRT()

local Timer = dcrt:NewAddon("Timer")
local timerFrame = CreateFrame("Frame", "DCRTTimer")

local timers = {}

-- Initialize for timers.
local lastcall = time()
timerFrame:SetScript("OnUpdate", function()
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

function Timer:Release()
	for k, v in ipairs(timers) do
		if v == self then
			table.remove(timers, k)
			break
		end
	end
end

function DCRTTimer(initval, handler)
	if initval then
		assert(type(initval) == "number", "Initval must be number.")
	end
	
	if handler then
		assert(type(handler) == "function", "Handler must be function.")
	end
	
	local timer = {
		initval = initval or 1
	}
	setmetatable(timer, {
		__index = Timer
	})
	table.insert(self.timers, timer)
	return timer
end
