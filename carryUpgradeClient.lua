-- Put this in StarterPlayer > StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the proximity prompt (adjust the path to where your proximity prompt is)
local workspace = game:GetService("Workspace")
local proximityPrompt = workspace.Environment.Shops:WaitForChild("WeaponsUpgradesShop"):WaitForChild("WeaponsStation"):WaitForChild("ProximityPrompt") -- Change this path!

-- Create the GUI
local function createUpgradeGui()
	local screenGui = playerGui:WaitForChild("BrainrotUpgradeGui")



	local mainFrame = screenGui:WaitForChild("MainFrame")

	-- Add corner radius
	local corner = mainFrame.UICorner

	-- Title
	local title = mainFrame.Title

	-- Current capacity display
	local capacityLabel = mainFrame.CapacityLabel

	-- Cost display
	local costLabel = mainFrame.CostLabel

	-- Upgrade button
	local upgradeButton = mainFrame.UpgradeButton
	

	local upgradeCorner = mainFrame.UICorner
	
	-- Close button
	local closeButton = mainFrame.CloseButton

	local closeCorner = closeButton.UICorner

	-- Status message
	local statusLabel = mainFrame.StatusLabel

	return screenGui
end

-- Get or create the GUI
local upgradeGui = playerGui:FindFirstChild("BrainrotUpgradeGui") or createUpgradeGui()

-- Update the GUI with current stats
local function updateGui()
	local currentCapacity = player:GetAttribute("BrainrotCapacity") or 1
	local upgradeCost = player:GetAttribute("NextUpgradeCost") or 100

	local capacityLabel = upgradeGui.MainFrame.CapacityLabel
	local costLabel = upgradeGui.MainFrame.CostLabel

	capacityLabel.Text = "Current Capacity: " .. currentCapacity
	costLabel.Text = "Next Upgrade Cost: $" .. upgradeCost
end

-- When proximity prompt is triggered
proximityPrompt.Triggered:Connect(function()
	upgradeGui.Enabled = not upgradeGui.Enabled

	if upgradeGui.Enabled then
		updateGui()
		upgradeGui.MainFrame.StatusLabel.Text = ""
	end
end)

-- Close button
upgradeGui.MainFrame.CloseButton.MouseButton1Click:Connect(function()
	upgradeGui.Enabled = false
end)

-- Upgrade button
upgradeGui.MainFrame.UpgradeButton.MouseButton1Click:Connect(function()
	-- Fire to server
	local upgradeEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpgradeBrainrotCapacity")
	upgradeEvent:FireServer()
end)

-- Listen for server response
local upgradeEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpgradeBrainrotCapacity")
upgradeEvent.OnClientEvent:Connect(function(success, message)
	local statusLabel = upgradeGui.MainFrame.StatusLabel

	if success then
		statusLabel.Text = "? " .. message
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		updateGui()
	else
		statusLabel.Text = "? " .. message
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	-- Clear message after 3 seconds
	task.delay(3, function()
		if statusLabel then
			statusLabel.Text = ""
		end
	end)
end)

print("? Brainrot Upgrade GUI loaded!")