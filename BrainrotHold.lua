-- Put this in StarterPlayer > StarterCharacterScripts
-- This will automatically position ANY tool with a Rarity attribute above the player's head
local brainrotevent = game.ReplicatedStorage.RemoteEvents.pickupbrainrot
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local dropgui = player.PlayerGui:WaitForChild("DropBrainrotGui")
-- Wait for necessary body parts
local head = character:WaitForChild("Head")
local rootPart = character:WaitForChild("HumanoidRootPart")
local leftShoulder = character:WaitForChild("LeftUpperArm", 5)
local rightShoulder = character:WaitForChild("RightUpperArm", 5)

-- Track current brainrot tool
local currentBrainrotTool = nil
local customWeld = nil
local leftArmWeld = nil
local rightArmWeld = nil
local originalCollisionStates = {}

-- Arm raising animation setup
local function raiseArms()
	if not leftShoulder or not rightShoulder then return end

	if not leftArmWeld then
		leftArmWeld = Instance.new("Weld")
		leftArmWeld.Name = "LeftArmRaise"
		leftArmWeld.Part0 = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		leftArmWeld.Part1 = leftShoulder
		leftArmWeld.C0 = CFrame.new(-1.5, 0.5, 0) * CFrame.Angles(math.rad(180), 0, 0)
		leftArmWeld.Parent = leftArmWeld.Part0
	end

	if not rightArmWeld then
		rightArmWeld = Instance.new("Weld")
		rightArmWeld.Name = "RightArmRaise"
		rightArmWeld.Part0 = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		rightArmWeld.Part1 = rightShoulder
		rightArmWeld.C0 = CFrame.new(1.5, 0.5, 0) * CFrame.Angles(math.rad(180), 0, 0)
		rightArmWeld.Parent = rightArmWeld.Part0
	end
end

local function lowerArms()
	if leftArmWeld then
		leftArmWeld:Destroy()
		leftArmWeld = nil
	end
	if rightArmWeld then
		rightArmWeld:Destroy()
		rightArmWeld = nil
	end
end

-- Clean up physics objects that interfere with movement
local function cleanupPhysicsObjects(tool)
	local removedCount = 0

	for _, descendant in pairs(tool:GetDescendants()) do
		-- Remove BodyVelocity, BodyGyro, and other physics movers
		if descendant:IsA("BodyVelocity") or 
			descendant:IsA("BodyGyro") or 
			descendant:IsA("BodyPosition") or
			descendant:IsA("BodyForce") or
			descendant:IsA("BodyThrust") or
			descendant:IsA("BodyAngularVelocity") then
			descendant:Destroy()
			removedCount = removedCount + 1
		end
	end

	if removedCount > 0 then
		print("?? Removed", removedCount, "physics objects")
	end
end

-- Disable collision on all brainrot parts
local function disableBrainrotCollision(tool)
	originalCollisionStates = {}
	local partsFound = 0

	for _, descendant in pairs(tool:GetDescendants()) do
		if descendant:IsA("BasePart") then
			partsFound = partsFound + 1
			originalCollisionStates[descendant] = descendant.CanCollide
			descendant.CanCollide = false
		end
	end

	print("?? Disabled collision on", partsFound, "parts")
end

-- Restore collision on all brainrot parts
local function restoreBrainrotCollision(tool)
	for part, originalState in pairs(originalCollisionStates) do
		if part and part.Parent then
			part.CanCollide = originalState
		end
	end

	originalCollisionStates = {}
end

local function positionBrainrotAboveHead(tool)
	local handle = tool:FindFirstChild("Handle")
	if not handle then 
		print("? No Handle found!")
		return 
	end

	-- Destroy the default RightGrip
	local rightGrip = character:FindFirstChild("RightGrip")
	if rightGrip then
		rightGrip:Destroy()
	end

	-- CRITICAL: Remove physics objects that cause movement issues
	cleanupPhysicsObjects(tool)

	-- Disable collision
	disableBrainrotCollision(tool)

	-- Create custom weld to position above head
	customWeld = Instance.new("Weld")
	customWeld.Name = "BrainrotWeld"
	customWeld.Part0 = head
	customWeld.Part1 = handle
	customWeld.C0 = CFrame.new(0, 6, 0) * CFrame.Angles(0, 0, 0)
	customWeld.Parent = handle

	-- Raise arms
	raiseArms()

	print("?? Positioned brainrot above head:", tool.Name)
end

local function onToolEquipped(tool)
	if tool:GetAttribute("Rarity") then
		currentBrainrotTool = tool

		task.wait(0.05)

		positionBrainrotAboveHead(tool)
		dropgui.Enabled = true
	end

end

local function onToolUnequipped(tool)
	if tool == currentBrainrotTool then
		restoreBrainrotCollision(tool)

		if customWeld then
			customWeld:Destroy()
			customWeld = nil
		end

		lowerArms()

		currentBrainrotTool = nil
		dropgui.Enabled = false

	end
end


character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		onToolEquipped(child)
	end
end)

character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") then
		onToolUnequipped(child)
	end
end)

local equippedTool = character:FindFirstChildOfClass("Tool")
if equippedTool then
	onToolEquipped(equippedTool)
end
brainrotevent.OnClientEvent:Connect(function(brainrot)
	print(brainrot.Name)
end)
print("? Brainrot Overhead Positioning loaded!")