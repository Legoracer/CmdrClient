-- Log
-- Stephen Leitnick
-- April 20, 2021

--[[

	IMPORTANT: Only make one logger per script/module


	Log.Level { Debug, Info, Warn, Severe }
	Log.TimeUnit { Milliseconds, Seconds, Minutes, Hours, Days, Weeks, Months, Years }

	Constructor:

		logger = Log.new()


	Log:

		Basic logging at levels:

			logger:AtDebug():Log("Hello from debug")
			logger:AtInfo():Log("Hello from info")
			logger:AtWarn():Log("Hello from warn")
			logger:AtSevere():Log("Hello from severe")
			logger:At(Log.Level.Warn):Log("Warning!")


		Log every 10 logs:

			logger:AtInfo():Every(10):Log("Log this only every 10 times")


		Log at most every 3 seconds:

			logger:AtInfo():AtMostEvery(3, Log.TimeUnit.Seconds):Log("Hello there, but not too often!")


	--------------------------------------------------------------------------------------------------------------

	LogConfig: Create a LogConfig ModuleScript anywhere in ReplicatedStorage. The configuration lets developers
	tune the lowest logging level based on various environment conditions. The LogConfig will be automatically
	required and used to set the log level.

	To set the default configuration for all environments, simply return the log level from the LogConfig:

		return "Info"

	To set a configuration that is different while in Studio:

		return {
			Studio = "Debug";
			Other = "Warn"; -- "Other" can be anything other than Studio (e.g. could be named "Default")
		}

	Fine-tune between server and client:

		return {
			Studio = {
				Server = "Info";
				Client = "Debug";
			};
			Other = "Warn";
		}

	Fine-tune based on PlaceIds:

		return {
			Studio = {
				Server = "Info";
				Client = "Debug";
			};
			Other = {
				PlaceIds = {123456, 234567}
				Server = "Severe";
				Client = "Warn";
			};
		}

	Fine-tune based on GameIds:

		return {
			Studio = {
				Server = "Info";
				Client = "Debug";
			};
			Other = {
				GameIds = {123456, 234567}
				Server = "Severe";
				Client = "Warn";
			};
		}

	Example of full-scale config with multiple environments:

		return {
			Studio = {
				Server = "Debug";
				Client = "Debug";
			};
			Dev = {
				PlaceIds = {1234567}
				Server = "Info";
				Client = "Info";
			};
			Prod = {
				PlaceIds = {2345678}
				Server = "Severe";
				Client = "Warn";
			};
			Default = "Info";
		}

--]]


local IS_STUDIO = game:GetService("RunService"):IsStudio()
local IS_SERVER = game:GetService("RunService"):IsServer()

local configModule = game:GetService("ReplicatedStorage"):FindFirstChild("LogConfig", true)
local config = (configModule and require(configModule) or "Debug")

local logLevel = nil
local timeFunc = os.clock

local timeUnits = {
	Milliseconds = 0;
	Seconds = 1;
	Minutes = 2;
	Hours = 3;
	Days = 4;
	Weeks = 5;
	Months = 6;
	Years = 7;
}

local function ToSeconds(n, timeUnit)
	if (timeUnit == timeUnits.Milliseconds) then
		return n / 1000
	elseif (timeUnit == timeUnits.Seconds) then
		return n
	elseif (timeUnit == timeUnits.Minutes) then
		return n * 60
	elseif (timeUnit == timeUnits.Hours) then
		return n * 3600
	elseif (timeUnit == timeUnits.Days) then
		return n * 86400
	elseif (timeUnit == timeUnits.Weeks) then
		return n * 604800
	elseif (timeUnit == timeUnits.Months) then
		return n * 2592000
	elseif (timeUnit == timeUnits.Years) then
		return n * 31536000
	else
		error("Unknown time unit", 2)
	end
end


local LogItem = {}
LogItem.__index = LogItem

function LogItem.new(log, levelName, key)
	local self = setmetatable({
		_log = log;
		_levelName = levelName;
		_modifiers = {};
		_key = key;
	}, LogItem)
	return self
end

function LogItem:_shouldLog(stats)
	if (self._modifiers.Every and not stats:_checkAndIncrementCount(self._modifiers.Every)) then
		return false
	end
	if (self._modifiers.AtMostEvery and not stats:_checkLastTimestamp(timeFunc(), self._modifiers.AtMostEvery)) then
		return false
	end
	return true
end

function LogItem:Every(n)
	self._modifiers.Every = n
	return self
end

function LogItem:AtMostEvery(n, timeUnit)
	self._modifiers.AtMostEvery = ToSeconds(n, timeUnit)
	return self
end

function LogItem:Log(...)
	local stats = self._log:_getLogStats(self._key)
	if (not self:_shouldLog(stats)) then return end
	local args = table.pack(...)
	for i,arg in ipairs(args) do
		if (type(arg) == "function") then
			args[i] = arg()
		end
	end
	stats:_setTimestamp(timeFunc())
	print(("%s: [%s]"):format(self._log._name, self._levelName), table.unpack(args))
end


local LogItemBlank = {}
LogItemBlank.__index = LogItemBlank
setmetatable(LogItemBlank, LogItem)

function LogItemBlank.new(...)
	local self = setmetatable(LogItem.new(...), LogItemBlank)
	return self
end

function LogItemBlank:Log()
	-- Do nothing
end


local LogStats = {}
LogStats.__index = LogStats

function LogStats.new()
	local self = setmetatable({}, LogStats)
	self._invocationCount = 0
	self._lastTimestamp = 0
	return self
end

function LogStats:_checkAndIncrementCount(rateLimit)
	local check = ((self._invocationCount % rateLimit) == 0)
	self._invocationCount += 1
	return check
end

function LogStats:_checkLastTimestamp(now, intervalSeconds)
	return ((now - self._lastTimestamp) >= intervalSeconds)
end

function LogStats:_setTimestamp(now)
	self._lastTimestamp = now
end


local Log = {}
Log.__index = Log


Log.TimeUnit = timeUnits

Log.Level = {
	Debug = 0;
	Info = 1;
	Warn = 2;
	Severe = 3;
}

Log.LevelNames = {}
for name,num in pairs(Log.Level) do
	Log.LevelNames[num] = name
end


function Log.new()
	local self = setmetatable({}, Log)
	local name = debug.info(2, "s"):match("%.(.-)$")
	self._name = name
	self._stats = {}
	return self
end


function Log:_getLogStats(key)
	local stats = self._stats[key]
	if (not stats) then
		stats = LogStats.new()
		self._stats[key] = stats
	end
	return stats
end


function Log:_at(level)
	local l, f = debug.info(3, "lf")
	local key = (tostring(l) .. tostring(f))
	if (level < logLevel) then
		return LogItemBlank.new(self, Log.LevelNames[level], key)
	else
		return LogItem.new(self, Log.LevelNames[level], key)
	end
end


function Log:At(level)
	return self:_at(level)
end


function Log:AtDebug()
	return self:_at(Log.Level.Debug)
end


function Log:AtInfo()
	return self:_at(Log.Level.Info)
end


function Log:AtWarn()
	return self:_at(Log.Level.Warn)
end


function Log:AtSevere()
	return self:_at(Log.Level.Severe)
end


function Log:Destroy()
end


function Log:__tostring()
	return ("Log<%s>"):format(self._name)
end


-- Determine log level:
do
	local function SetLogLevel(name)
		local n = name:lower()
		for levelName,level in pairs(Log.Level) do
			if (levelName:lower() == n) then
				logLevel = level
				return
			end
		end
		error("Unknown log level: " .. tostring(name))
	end
	local configType = type(config)
	assert(configType == "table" or configType == "string", "LogConfig must return a table or a string; got " .. configType)
	if (configType == "string") then
		SetLogLevel(config)
	else
		if (IS_STUDIO and config.Studio) then
			local studioConfigType = type(config.Studio)
			assert(studioConfigType == "table" or studioConfigType == "string", "LogConfig.Studio must be a table or a string; got " .. studioConfigType)
			if (studioConfigType == "string") then
				-- Config for Studio:
				SetLogLevel(config.Studio)
			else
				-- Server/Client config for Studio:
				if (IS_SERVER) then
					local studioServerLevel = config.Studio.Server
					assert(type(studioServerLevel) == "string", "LogConfig.Studio.Server must be a string; got " .. type(studioServerLevel))
					SetLogLevel(studioServerLevel)
				else
					local studioClientLevel = config.Studio.Client
					assert(type(studioClientLevel) == "string", "LogConfig.Studio.Client must be a string; got " .. type(studioClientLevel))
					SetLogLevel(studioClientLevel)
				end
			end
		else
			local default = nil
			local numDefault = 0
			local set = false
			local setK = nil
			for k,specialConfig in pairs(config) do
				if (k == "Studio") then continue end
				if (type(specialConfig) == "string") then
					default = specialConfig
					numDefault += 1
				elseif (type(specialConfig) == "table") then
					-- Check if config can be used if filtered by PlaceId or GameId:
					local canUse, fallthrough = false, false
					if (type(specialConfig.PlaceId) == "number") then
						canUse = (specialConfig.PlaceId == game.PlaceId)
					elseif (type(specialConfig.PlaceIds) == "table") then
						canUse = (table.find(specialConfig.PlaceIds, game.PlaceId) ~= nil)
					elseif (type(specialConfig.GameId) == "number") then
						canUse = (specialConfig.GameId == game.GameId)
					elseif (type(specialConfig.GameIds) == "table") then
						canUse = (table.find(specialConfig.GameIds, game.GameId) ~= nil)
					else
						canUse = true
						fallthrough = true
					end
					if (not fallthrough) then
						assert(not set, ("More than one LogConfig mapping matched (%s and %s)"):format(setK or "", k or ""))
					end
					if (canUse) then
						if (IS_SERVER) then
							local serverLevel = specialConfig.Server
							assert(type(serverLevel) == "string", ("LogConfig.%s.Server must be a string; got %s"):format(k, type(serverLevel)))
							SetLogLevel(serverLevel)
							set = true
							setK = k
						else
							local clientLevel = specialConfig.Client
							assert(type(clientLevel) == "string", ("LogConfig.%s.Client must be a string; got %s"):format(k, type(clientLevel)))
							SetLogLevel(clientLevel)
							set = true
							setK = k
						end
					end
				else
					warn(("LogConfig.%s must be a table or a string; got %s"):format(k, typeof(specialConfig)))
				end
			end
			if (numDefault > 1) then
				warn("Ambiguous default logging level")
			end
			if (default and not set) then
				SetLogLevel(default)
			end
		end
	end
	assert(type(logLevel) == "number", "LogLevel failed to be determined")
end


return Log