-- WeatherSystem (ModuleScript) -- place in ReplicatedStorage
-- Manages weather states that enable Limited mutations during events

local WeatherSystem = {}

-- ============================================================
--  WEATHER DEFINITIONS
--  Each weather maps to one Limited mutation from the wiki.
--  limitedChance = rolls out of 1000 during active weather.
-- ============================================================
WeatherSystem.WEATHER_TYPES = {
	["Clear"] = {
		displayName   = "?? Clear Skies",
		mutation      = nil,       -- no limited mutation during clear
		limitedChance = 0,
		color         = Color3.fromRGB(135, 206, 235),
		description   = "Normal spawns.",
	},
	["Bloodstorm"] = {
		displayName   = "?? Bloodstorm",
		mutation      = "Bloodrot",
		limitedChance = 150,        -- 4% chance per spawn during event
		color         = Color3.fromRGB(139, 0, 0),
		description   = "Dark clouds bring Bloodrot mutations!",
	},
	["Rain"] = {
		displayName   = "??? Rain",
		mutation      = "Wet",
		limitedChance = 150,        -- 2% chance per spawn during event
		color         = Color3.fromRGB(135, 206, 235),
		description   = "Rain brings Wet mutations!",
	},

	["Candyland"] = {
		displayName   = "?? Candy Rain",
		mutation      = "Candy",
		limitedChance = 150,        -- 2.5% — rarer because 4x mult
		color         = Color3.fromRGB(255, 182, 193),
		description   = "Sweet showers bring Candy mutations!",
	},
	["Volcanic"] = {
		displayName   = "?? Volcanic Eruption",
		mutation      = "Lava",
		limitedChance = 150,        -- ~1.8% — 6x mult
		color         = Color3.fromRGB(255, 69, 0),
		description   = "Scorching heat brings Lava mutations!",
	},
	["Galactic"] = {
		displayName   = "?? Galactic Storm",
		mutation      = "Galaxy",
		limitedChance = 150,        -- ~1.5% — 7x mult
		color         = Color3.fromRGB(75, 0, 130),
		description   = "Cosmic energy brings Galaxy mutations!",
	},
	["YinYang"] = {
		displayName   = "?? Balance Shift",
		mutation      = "Yin-Yang",
		limitedChance = 150,        -- ~1.2% — 7.5x mult
		color         = Color3.fromRGB(50, 50, 50),
		description   = "Reality splits, bringing Yin-Yang mutations!",
	},
	["Radioactive"] = {
		displayName   = "?? Toxic Fallout",
		mutation      = "Radioactive",
		limitedChance = 150,         -- 0.8% — 8.5x mult (near-Rainbow tier)
		color         = Color3.fromRGB(0, 255, 50),
		description   = "Toxic rain brings Radioactive mutations!",
	},
}

-- ============================================================
--  WEATHER EVENT RARITY (WEIGHTS)
--  Higher number = more common. 
--  (e.g., 4 means it gets added to the selection pool 4 times)
-- ============================================================
WeatherSystem.EVENT_WEIGHTS = {
	["Bloodstorm"]  = 1,
	["Candyland"]   = 1,
	["Volcanic"]    = 1,
	["Galactic"]    = 1,
	["YinYang"]     = 1,
	["Radioactive"] = 1,
	["Rain"]        = 1, -- Set higher to make Rain more common!
}

-- Auto-generate the WEATHER_EVENTS array based on the weights above.
-- This keeps your external scripts working perfectly without modifications!
WeatherSystem.WEATHER_EVENTS = {}
for weatherName, weight in pairs(WeatherSystem.EVENT_WEIGHTS) do
	for i = 1, weight do
		table.insert(WeatherSystem.WEATHER_EVENTS, weatherName)
	end
end

-- Duration config (seconds)
WeatherSystem.EVENT_DURATION  = 15   -- how long each weather event lasts
WeatherSystem.CLEAR_DURATION  = 15    -- gap between events

-- ============================================================
--  LIMITED MUTATION MULTIPLIERS
-- ============================================================
WeatherSystem.LIMITED_MULTIPLIERS = {
	["Bloodrot"]    = 2.0,
	["Candy"]       = 4.0,
	["Lava"]        = 6.0,
	["Galaxy"]      = 7.0,
	["Yin-Yang"]    = 7.5,
	["Radioactive"] = 8.5,
	["Wet"] = 1.5
}

-- ============================================================
--  LIMITED MUTATION VISUALS
--  Colors/effects applied server-side (SurfaceAppearance removed)
-- ============================================================
WeatherSystem.LIMITED_VISUALS = {
	["Bloodrot"] = {
		color       = Color3.fromRGB(100, 0, 0),
		material    = Enum.Material.SmoothPlastic,
		reflectance = 0,
		animated    = false,
	},
	["Candy"] = {
		color       = Color3.fromRGB(255, 105, 180),
		material    = Enum.Material.SmoothPlastic,
		reflectance = 0.1,
		animated    = false,
	},
	["Lava"] = {
		color       = Color3.fromRGB(255, 80, 0),
		material    = Enum.Material.Neon,   -- glowing neon orange
		reflectance = 0,
		animated    = false,
	},
	["Galaxy"] = {
		color       = Color3.fromRGB(138, 43, 226),
		material    = Enum.Material.Neon,
		reflectance = 0,
		animated    = "galaxy",   -- slow purple pulse
	},
	["Yin-Yang"] = {
		color       = nil,        -- handled specially (alternating B&W)
		material    = Enum.Material.SmoothPlastic,
		reflectance = 0,
		animated    = "yinyang",
	},
	["Radioactive"] = {
		color       = Color3.fromRGB(0, 255, 50),
		material    = Enum.Material.Neon,
		reflectance = 0,
		animated    = "radioactive",  -- fast green pulse
	},
	["Wet"] = {
		color       = Color3.fromRGB(84, 130, 255),
		material    = Enum.Material.Neon,
		reflectance = 0,
		animated    = "wet",  -- fast green pulse
	}
}

-- ============================================================
--  STATE  (runtime, not saved)
-- ============================================================
WeatherSystem._currentWeather  = "Clear"
WeatherSystem._weatherEndTime  = 0
WeatherSystem._lastEventIndex  = 0

-- ============================================================
--  PUBLIC API
-- ============================================================

function WeatherSystem.getCurrentWeather()
	return WeatherSystem._currentWeather
end

function WeatherSystem.getWeatherData(weatherName)
	return WeatherSystem.WEATHER_TYPES[weatherName]
end

-- Returns the limited mutation name if one is active, else nil
function WeatherSystem.getActiveLimitedMutation()
	local data = WeatherSystem.WEATHER_TYPES[WeatherSystem._currentWeather]
	if data then return data.mutation end
	return nil
end

-- Returns limitedChance (out of 1000) for current weather
function WeatherSystem.getLimitedChance()
	local data = WeatherSystem.WEATHER_TYPES[WeatherSystem._currentWeather]
	if data then return data.limitedChance end
	return 0
end

return WeatherSystem