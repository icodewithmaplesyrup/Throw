-- RemoteSetup (Script) -- place in ServerScriptService
-- Runs FIRST to guarantee all RemoteEvents exist before any LocalScript loads.
-- Set RunContext to "Server" or just leave it as a normal Script.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure the folder exists
local Remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "RemoteEvents"
	Remotes.Parent = ReplicatedStorage
end

local function ensureRemoteEvent(name)
	if not Remotes:FindFirstChild(name) then
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = Remotes
	end
end

local function ensureRemoteFunction(name)
	if not Remotes:FindFirstChild(name) then
		local r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = Remotes
	end
end

-- Spawn system remotes (your existing script uses these)
ensureRemoteEvent("randombrainrot")
ensureRemoteEvent("AutoSpawn")
ensureRemoteEvent("SpawnSpecificBrainrot")

-- Weather system remotes
ensureRemoteEvent("WeatherChanged")
ensureRemoteFunction("GetCurrentWeather")
ensureRemoteEvent("ForceWeather")

print("? RemoteSetup: All RemoteEvents pre-created.")