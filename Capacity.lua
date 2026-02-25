local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local purchaseGui = playerGui:WaitForChild("PurchaseGui")
-- The new Red Frame
local capacityFrame = purchaseGui:WaitForChild("CapacityFrame") 

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local capacityEvent = remoteEvents:WaitForChild("CapacityFullEvent")

-- Animation State Variables
local currentTween = nil
local hideTask = nil

local function playCapacityNotification()
	-- 1. CANCEL OLD TIMERS
	if hideTask then
		task.cancel(hideTask)
		hideTask = nil
	end

	-- 2. STOP CURRENT MOTION
	if currentTween then
		currentTween:Cancel()
	end

	-- 3. RESET
	capacityFrame.Visible = true
	capacityFrame.ZIndex = 102 -- Highest priority (above bounce)

	-- If frame is currently hidden (off screen), reset to start position
	if capacityFrame.Position.Y.Scale < 0 then
		capacityFrame.Position = UDim2.new(0.5, 0, -0.3, 0)
	end

	-- DROP ANIMATION (Elastic Out)
	local dropInfo = TweenInfo.new(
		1.2, 
		Enum.EasingStyle.Elastic, 
		Enum.EasingDirection.Out
	)

	currentTween = TweenService:Create(capacityFrame, dropInfo, {
		Position = UDim2.new(0.5, 0, 0.15, 0)
	})
	currentTween:Play()

	-- 4. WAIT & HIDE
	hideTask = task.spawn(function()
		task.wait(2.5) 

		local upInfo = TweenInfo.new(
			0.6,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In
		)

		currentTween = TweenService:Create(capacityFrame, upInfo, {
			Position = UDim2.new(0.5, 0, -0.3, 0)
		})
		currentTween:Play()
		currentTween.Completed:Wait()

		capacityFrame.Visible = false
		hideTask = nil
		currentTween = nil
	end)
end

capacityEvent.OnClientEvent:Connect(playCapacityNotification)