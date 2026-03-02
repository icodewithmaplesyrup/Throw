-- WeatherVisualClient (LocalScript) -- place in StarterPlayerScripts
-- Applies Atmosphere + Skybox presets when weather changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local weatherChangedEvent = Remotes:WaitForChild("WeatherChanged")
local getWeatherFunc = Remotes:WaitForChild("GetCurrentWeather")
local WeatherSystem = require(ReplicatedStorage:WaitForChild("WeatherSystem"))
local AtmosIntegration = require(ReplicatedStorage:WaitForChild("AtmosIntegration"))

local MANAGED_SKY_NAME = "ManagedWeatherSky"
local MANAGED_ATMOS_NAME = "ManagedWeatherAtmosphere"

local function upsertSky()
	local sky = Lighting:FindFirstChild(MANAGED_SKY_NAME)
	if sky and sky:IsA("Sky") then
		return sky
	end

	if sky and not sky:IsA("Sky") then
		sky:Destroy()
	end

	sky = Instance.new("Sky")
	sky.Name = MANAGED_SKY_NAME
	sky.Parent = Lighting
	return sky
end

local function upsertAtmosphere()
	local atmosphere = Lighting:FindFirstChild(MANAGED_ATMOS_NAME)
	if atmosphere and atmosphere:IsA("Atmosphere") then
		return atmosphere
	end

	if atmosphere and not atmosphere:IsA("Atmosphere") then
		atmosphere:Destroy()
	end

	atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = MANAGED_ATMOS_NAME
	atmosphere.Parent = Lighting
	return atmosphere
end

local function applySkybox(skybox)
	local sky = upsertSky()

	sky.SkyboxBk = skybox.SkyboxBk or ""
	sky.SkyboxDn = skybox.SkyboxDn or ""
	sky.SkyboxFt = skybox.SkyboxFt or ""
	sky.SkyboxLf = skybox.SkyboxLf or ""
	sky.SkyboxRt = skybox.SkyboxRt or ""
	sky.SkyboxUp = skybox.SkyboxUp or ""
	sky.CelestialBodiesShown = skybox.CelestialBodiesShown ~= false
	sky.StarCount = skybox.StarCount or 0
	sky.SunAngularSize = skybox.SunAngularSize or 21
	sky.MoonAngularSize = skybox.MoonAngularSize or 11
end

local function applyAtmosphere(atmosData, tweenTime)
	local atmosphere = upsertAtmosphere()

	local target = {
		Density = atmosData.Density or 0.25,
		Offset = atmosData.Offset or 0,
		Color = atmosData.Color or Color3.fromRGB(199, 199, 199),
		Decay = atmosData.Decay or Color3.fromRGB(106, 112, 125),
		Glare = atmosData.Glare or 0,
		Haze = atmosData.Haze or 0,
	}

	if tweenTime and tweenTime > 0 then
		local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local tween = TweenService:Create(atmosphere, tweenInfo, target)
		tween:Play()
	else
		for k, v in pairs(target) do
			atmosphere[k] = v
		end
	end
end

local function applyLighting(data)
	if data.Brightness ~= nil then Lighting.Brightness = data.Brightness end
	if data.ClockTime ~= nil then Lighting.ClockTime = data.ClockTime end
	if data.FogEnd ~= nil then Lighting.FogEnd = data.FogEnd end
	if data.FogColor ~= nil then Lighting.FogColor = data.FogColor end
	if data.Ambient ~= nil then Lighting.Ambient = data.Ambient end
	if data.OutdoorAmbient ~= nil then Lighting.OutdoorAmbient = data.OutdoorAmbient end
end

local function applyWeatherVisuals(weatherName)
	-- Priority: Atmos by elttob authored folder presets -> fallback table presets
	local preset = AtmosIntegration.getPreset(weatherName)
	if not preset then
		preset = WeatherSystem.ATMOS_PRESETS and WeatherSystem.ATMOS_PRESETS[weatherName]
	end
	if not preset then
		preset = AtmosIntegration.getPreset("Clear") or (WeatherSystem.ATMOS_PRESETS and WeatherSystem.ATMOS_PRESETS.Clear)
	end
	if not preset then return end

	applySkybox(preset.skybox or {})

	if preset.atmosphere then
		applyAtmosphere(preset.atmosphere, preset.transitionTime)
	end

	if preset.lighting then
		applyLighting(preset.lighting)
	end
end

weatherChangedEvent.OnClientEvent:Connect(function(weatherName)
	applyWeatherVisuals(weatherName)
end)

-- Sync late joiners
local ok, currentWeather = pcall(function()
	return getWeatherFunc:InvokeServer()
end)
if ok and currentWeather then
	applyWeatherVisuals(currentWeather)
else
	applyWeatherVisuals("Clear")
end
