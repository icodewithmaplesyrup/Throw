local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local flyEvent = ReplicatedStorage:WaitForChild("AdminFlyEvent")

local canFly = false 
local isFlying = false
local lastJump = 0
local speed = 500
local bv, bg

local function stopFlying()
	isFlying = false
	if bv then bv:Destroy() bv = nil end
	if bg then bg:Destroy() bg = nil end
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.PlatformStand = false
	end
end

local function startFlying()
	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not hrp or not hum then return end

	isFlying = true
	hum.PlatformStand = true
	bv = Instance.new("BodyVelocity", hrp)
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bg = Instance.new("BodyGyro", hrp)
	bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

	task.spawn(function()
		while isFlying and char.Parent do
			local move = Vector3.new(0,0,0)
			-- Keyboard Input
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end

			-- Mobile Joystick + Combined Logic
			local finalMove = move + hum.MoveDirection
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then finalMove += Vector3.new(0,1,0)
			elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then finalMove -= Vector3.new(0,1,0) end

			bv.Velocity = (finalMove.Magnitude > 0) and (finalMove.Unit * speed) or Vector3.new(0,0,0)
			bg.CFrame = camera.CFrame
			RunService.RenderStepped:Wait()
		end
		stopFlying()
	end)
end

-- SERVER TOGGLE RECEIVER
flyEvent.OnClientEvent:Connect(function(state)
	canFly = state -- State is true or false
	if not canFly and isFlying then
		stopFlying()
	end
	print(canFly and "?? Fly Perms ENABLED" or "? Fly Perms DISABLED")
end)

-- DOUBLE JUMP DETECTION (iPad & PC)
UserInputService.JumpRequest:Connect(function()
	if not canFly then return end
	local now = tick()
	if now - lastJump < 0.3 then
		if isFlying then stopFlying() else startFlying() end
	end
	lastJump = now
end)
