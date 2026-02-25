local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local basesFolder = Workspace:WaitForChild("BrainrotBases")
local INDICATOR_NAME = "YourBaseIndicator" -- Must match exactly

local function updateBaseVisuals(base)
	-- Safely check if the parts exist yet
	local spawnLocation = base:FindFirstChild("SpawnLocation")
	if not spawnLocation then return end

	local indicator = spawnLocation:FindFirstChild(INDICATOR_NAME)
	if not indicator then return end

	local ownerValue = base:FindFirstChild("Owner")
	local ownerName = ownerValue and ownerValue.Value or ""

	-- LOGIC: Only enable it if I own it. Otherwise, hide it.
	if ownerName == player.Name then
		indicator.Enabled = true
		print("? Showing base indicator for " .. base.Name)
	else
indicator.Enabled = false
	end
end

local function setupBase(base)
	-- 1. Try to update immediately
	updateBaseVisuals(base)

	-- 2. Listen for Ownership changes (When you claim the base)
	local ownerValue = base:WaitForChild("Owner", 10)
	if ownerValue then
		ownerValue.Changed:Connect(function()
			updateBaseVisuals(base)
		end)
	end

	-- 3. Listen for the Indicator loading in (In case of lag/streaming)
	local spawnLocation = base:WaitForChild("SpawnLocation", 10)
	if spawnLocation then
		spawnLocation.ChildAdded:Connect(function(child)
			if child.Name == INDICATOR_NAME then
				updateBaseVisuals(base)
			end
		end)

		-- Also check if indicator was already there inside spawnLocation
		updateBaseVisuals(base)
	end
end

-- Initialize existing bases
for _, base in pairs(basesFolder:GetChildren()) do
	setupBase(base)
end

-- Initialize future bases (if they are added later)
basesFolder.ChildAdded:Connect(setupBase)