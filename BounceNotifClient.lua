local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- Wait for your specific GUI
local purchaseGui = playerGui:WaitForChild("PurchaseGui") 
-- Wait for the new Green Frame you just made
local bounceFrame = purchaseGui:WaitForChild("BounceFrame") 

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local bounceEvent = remoteEvents:WaitForChild("BounceNotif")

-- Animation State Variables
local currentTween = nil
local hideTask = nil

local function playBounceNotification()
	-- 1. CANCEL OLD TIMERS
	if hideTask then
		task.cancel(hideTask)
		hideTask = nil
	end

	-- 2. STOP CURRENT MOTION
	if currentTween then
		currentTween:Cancel()
	end

	-- 3. RESET (Make sure it's visible and on top)
	bounceFrame.Visible = true
	bounceFrame.ZIndex = 101 -- Higher than everything else

	-- If frame is currently hidden (off screen), reset to start position
	if bounceFrame.Position.Y.Scale < 0 then
		bounceFrame.Position = UDim2.new(0.5, 0,-0.007, 0)
	end

	-- DROP ANIMATION (Elastic Out)
	local dropInfo = TweenInfo.new(
		1.2, 
		Enum.EasingStyle.Elastic, 
		Enum.EasingDirection.Out
	)

	currentTween = TweenService:Create(bounceFrame, dropInfo, {
		Position = UDim2.new(0.5, 0, 0.075, 0)
	})
	currentTween:Play()

	-- 4. WAIT & HIDE
	hideTask = task.spawn(function()
		task.wait(2.5) -- Kept it long enough to read the long text

		local upInfo = TweenInfo.new(
			0.6,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In
		)

		currentTween = TweenService:Create(bounceFrame, upInfo, {
			Position = UDim2.new(0.5, 0, -0.3, 0)
		})
		currentTween:Play()
		currentTween.Completed:Wait()

		bounceFrame.Visible = false
		hideTask = nil
		currentTween = nil
	end)
end

-- Listen for the Server to tell us to play the animation
bounceEvent.OnClientEvent:Connect(playBounceNotification)