-- StarterPlayer/StarterPlayerScripts/BaseUpgradeClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for RemoteEvent
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
	warn("RemoteEvents folder not found!")
	return
end

local upgradeBaseEvent = remoteEvents:WaitForChild("UpgradeBaseEvent", 10)
if not upgradeBaseEvent then
	warn("UpgradeBaseEvent not found!")
	return
end

-- Create UI for notifications
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeNotifications"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Function to show notification
local function showNotification(success, message)
	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(0, 400, 0, 80)
	notification.Position = UDim2.new(0.5, -200, 0.1, 0)
	notification.BackgroundColor3 = success and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(180, 40, 40)
	notification.BorderSizePixel = 0
	notification.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notification

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, -20)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 20
	label.Font = Enum.Font.SourceSansBold
	label.TextWrapped = true
	label.Parent = notification

	-- Animate in
	notification.BackgroundTransparency = 1
	label.TextTransparency = 1

	local tweenService = game:GetService("TweenService")
	local tweenIn = tweenService:Create(notification, TweenInfo.new(0.3), {BackgroundTransparency = 0})
	local tweenInText = tweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 0})

	tweenIn:Play()
	tweenInText:Play()

	-- Wait then fade out
	task.wait(3)

	local tweenOut = tweenService:Create(notification, TweenInfo.new(0.5), {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, -200, 0, 0)
	})
	local tweenOutText = tweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})

	tweenOut:Play()
	tweenOutText:Play()

	tweenOut.Completed:Connect(function()
		notification:Destroy()
	end)
end

-- Listen for upgrade events
upgradeBaseEvent.OnClientEvent:Connect(function(success, message)
	showNotification(success, message)
end)

print("? BaseUpgradeClient loaded!")