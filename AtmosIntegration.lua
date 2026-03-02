-- AtmosIntegration (ModuleScript) -- place in ReplicatedStorage
-- Bridges presets authored with Atmos by elttob into weather-ready runtime data.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AtmosIntegration = {}

local PRESET_FOLDER_NAME = "AtmosWeatherPresets"

local COLOR_KEYS = {
	Color = true,
	Decay = true,
	FogColor = true,
	Ambient = true,
	OutdoorAmbient = true,
}

local NUMBER_KEYS = {
	Density = true,
	Offset = true,
	Glare = true,
	Haze = true,
	Brightness = true,
	ClockTime = true,
	FogEnd = true,
	StarCount = true,
	SunAngularSize = true,
	MoonAngularSize = true,
	transitionTime = true,
}

local BOOL_KEYS = {
	CelestialBodiesShown = true,
}

local function parseColor(raw)
	if typeof(raw) == "Color3" then return raw end
	if typeof(raw) ~= "string" then return nil end
	local r, g, b = string.match(raw, "^(%d+),(%d+),(%d+)$")
	if not r then return nil end
	return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
end

local function parseValue(key, raw)
	if COLOR_KEYS[key] then
		return parseColor(raw)
	elseif NUMBER_KEYS[key] then
		return tonumber(raw)
	elseif BOOL_KEYS[key] then
		if typeof(raw) == "boolean" then return raw end
		return tostring(raw) == "true"
	else
		return raw
	end
end

local function readAttributes(instance, keyMap)
	local out = {}
	for key in pairs(keyMap) do
		local raw = instance:GetAttribute(key)
		if raw ~= nil then
			local parsed = parseValue(key, raw)
			if parsed ~= nil then
				out[key] = parsed
			end
		end
	end
	return out
end

function AtmosIntegration.getPreset(weatherName)
	local root = ReplicatedStorage:FindFirstChild(PRESET_FOLDER_NAME)
	if not root then return nil end

	local presetFolder = root:FindFirstChild(weatherName)
	if not presetFolder or not presetFolder:IsA("Folder") then return nil end

	local result = {
		transitionTime = presetFolder:GetAttribute("transitionTime"),
	}

	local atmosphere = presetFolder:FindFirstChild("Atmosphere")
	if atmosphere then
		result.atmosphere = readAttributes(atmosphere, {
			Density = true,
			Offset = true,
			Color = true,
			Decay = true,
			Glare = true,
			Haze = true,
		})
	end

	local lighting = presetFolder:FindFirstChild("Lighting")
	if lighting then
		result.lighting = readAttributes(lighting, {
			Brightness = true,
			ClockTime = true,
			FogEnd = true,
			FogColor = true,
			Ambient = true,
			OutdoorAmbient = true,
		})
	end

	local skybox = presetFolder:FindFirstChild("Sky")
	if skybox then
		result.skybox = {
			SkyboxBk = skybox:GetAttribute("SkyboxBk"),
			SkyboxDn = skybox:GetAttribute("SkyboxDn"),
			SkyboxFt = skybox:GetAttribute("SkyboxFt"),
			SkyboxLf = skybox:GetAttribute("SkyboxLf"),
			SkyboxRt = skybox:GetAttribute("SkyboxRt"),
			SkyboxUp = skybox:GetAttribute("SkyboxUp"),
			CelestialBodiesShown = parseValue("CelestialBodiesShown", skybox:GetAttribute("CelestialBodiesShown")),
			StarCount = parseValue("StarCount", skybox:GetAttribute("StarCount")),
			SunAngularSize = parseValue("SunAngularSize", skybox:GetAttribute("SunAngularSize")),
			MoonAngularSize = parseValue("MoonAngularSize", skybox:GetAttribute("MoonAngularSize")),
		}
	end

	return result
end

return AtmosIntegration
