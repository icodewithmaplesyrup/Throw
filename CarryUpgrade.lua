-- Put this in ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvent if it doesn't exist
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local upgradeEvent = remoteEvents:FindFirstChild("UpgradeBrainrotCapacity")
if not upgradeEvent then
	upgradeEvent = Instance.new("RemoteEvent")
	upgradeEvent.Name = "UpgradeBrainrotCapacity"
	upgradeEvent.Parent = remoteEvents
end

-- Upgrade costs (increases with each level)
local BASE_COST = 500,000
local COST_MULTIPLIER = 50

-- Calculate upgrade cost based on current capacity
local function calculateUpgradeCost(currentCapacity)
	return math.floor(BASE_COST * (COST_MULTIPLIER ^ (currentCapacity - 1)))
end

-- Initialize player data
local function setupPlayer(player)
	-- Set default capacity if not already set
	if not player:GetAttribute("BrainrotCapacity") then
		player:SetAttribute("BrainrotCapacity", 1)
	end

	-- Set initial upgrade cost
	local currentCapacity = player:GetAttribute("BrainrotCapacity")
	player:SetAttribute("NextUpgradeCost", calculateUpgradeCost(currentCapacity))

	print("?? " .. player.Name .. " initialized with capacity: " .. currentCapacity)
end

-- Handle upgrade request
upgradeEvent.OnServerEvent:Connect(function(player)
	local currentCapacity = player:GetAttribute("BrainrotCapacity") or 1
	local upgradeCost = player:GetAttribute("NextUpgradeCost") or 100

	-- Check if player has enough money
	local moneyRaw = player:FindFirstChild("MoneyRaw")
	if not moneyRaw then
		upgradeEvent:FireClient(player, false, "Money system not found!")
		return
	end

	-- Check if player can afford it
	if moneyRaw.Value < upgradeCost then
		upgradeEvent:FireClient(player, false, "Not enough money! Need $" .. upgradeCost)
		return
	end

	-- Check max capacity (optional)
	local MAX_CAPACITY = 10
	if currentCapacity >= MAX_CAPACITY then
		upgradeEvent:FireClient(player, false, "Maximum capacity reached!")
		return
	end

	-- Deduct money
	moneyRaw.Value = moneyRaw.Value - upgradeCost

	-- Increase capacity
	local newCapacity = currentCapacity + 1
	player:SetAttribute("BrainrotCapacity", newCapacity)

	-- Calculate new upgrade cost
	local newCost = calculateUpgradeCost(newCapacity)
	player:SetAttribute("NextUpgradeCost", newCost)

	-- Send success message
	upgradeEvent:FireClient(player, true, "Upgraded to capacity: " .. newCapacity)

	print("?? " .. player.Name .. " upgraded capacity to " .. newCapacity .. " for $" .. upgradeCost)
end)

-- Setup existing players
for _, player in pairs(Players:GetPlayers()) do
	setupPlayer(player)
end

-- Setup new players
Players.PlayerAdded:Connect(setupPlayer)

print("? Brainrot Capacity Upgrade System loaded!")