local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvent
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local throwMemeEvent = remoteEvents:WaitForChild("ThrowMemeEvent")

-- Create UI
local screenGui = playerGui:WaitForChild("ThrowingUI")

-- Power bar background (vertical)
local powerBarBg = screenGui:WaitForChild("PowerBarBackground")

local gradientFrame = powerBarBg.Frame
local gradientCorner = gradientFrame.UICorner
local gradient = gradientFrame.UIGradient

-- Moving indicator
local indicator = powerBarBg.Indicator

-- ---------------------------------------------------------
-- LOGIC
-- ---------------------------------------------------------

local isLoopActive = false
local currentPower = 0
local powerDirection = 1
local POWER_SPEED = 0.02

local function updatePowerBar()
	while isLoopActive and screenGui.Enabled do
		task.wait()
		currentPower = currentPower + (POWER_SPEED * powerDirection)
		if currentPower >= 1 then
			currentPower = 1
			powerDirection = -1
		elseif currentPower <= 0.01 then
			currentPower = 0.01
			powerDirection = 1
		end
		indicator.Position = UDim2.new(0, 0, currentPower, -4)
	end
end

local function getPowerPercentage()
	local distanceFromCenter = math.abs(currentPower - 0.5)
	local powerPercent = 1 - (distanceFromCenter * 2) 
	return math.max(0.01, powerPercent) 
end

local function getCurrentColor()
	local power = currentPower
	if power < 0.25 then
		local t = power / 0.25
		return Color3.fromRGB(220, 50 + (150 * t), 50)
	elseif power < 0.5 then
		local t = (power - 0.25) / 0.25
		return Color3.fromRGB(240 - (190 * t), 200 + (20 * t), 50 + (170 * t))
	elseif power < 0.75 then
		local t = (power - 0.5) / 0.25
		return Color3.fromRGB(50 + (190 * t), 220 - (20 * t), 220 - (170 * t))
	else
		local t = (power - 0.75) / 0.25
		return Color3.fromRGB(240 - (20 * t), 200 - (150 * t), 50)
	end
end

local function throwMeme(targetPosition)
	if not screenGui.Enabled or not isLoopActive then return end

	isLoopActive = false
	local powerPercent = getPowerPercentage()

	-- Visual feedback
	local lockColor = getCurrentColor()
	indicator.BackgroundColor3 = lockColor

	-- Handle default target if none provided (e.g. Spacebar)
	if not targetPosition then
		if player.Character and player.Character.PrimaryPart then
			targetPosition = player.Character.PrimaryPart.Position + (player.Character.PrimaryPart.CFrame.LookVector * 100)
		else
			targetPosition = Vector3.new(0, 0, 0)
		end
	end

	-- Send Power AND Position to server
	throwMemeEvent:FireServer(powerPercent, targetPosition)

	task.wait(0.5)

	if screenGui.Enabled then
		indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		isLoopActive = true
		task.spawn(updatePowerBar)
	end
end

-- ---------------------------------------------------------
-- INPUT HANDLING (Click Anywhere Logic)
-- ---------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- 1. If tool is not equipped, ignore everything
	if not screenGui.Enabled then return end

	-- 2. If user clicked a UI element (like chat), ignore
	if gameProcessed then return end

	-- 3. Check for Click (PC) or Touch (Mobile)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch then

		-- Use the mouse 3D position
		if mouse.Hit then
			throwMeme(mouse.Hit.Position)
		end
	end
end)

-- ---------------------------------------------------------
-- EQUIP / UNEQUIP HANDLING
-- ---------------------------------------------------------
local THROW_TOOL_NAME = "Tool" -- change to your actual tool name

local function bindTool(tool)
	if tool.Name ~= THROW_TOOL_NAME then return end

	tool.Equipped:Connect(function()
		screenGui.Enabled = true
		isLoopActive = true
		currentPower = 0.01
		indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		task.spawn(updatePowerBar)
	end)

	tool.Unequipped:Connect(function()
		screenGui.Enabled = false
		isLoopActive = false
	end)
end

local function setupCharacter(character)
	-- Bind already-equipped tools
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			bindTool(child)
		end
	end

	-- Bind future tools
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			bindTool(child)
		end
	end)
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)
