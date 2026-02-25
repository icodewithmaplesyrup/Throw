local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")

-- EVENTS
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local bounceNotificationEvent = remoteEvents:WaitForChild("BounceNotif")
local capacityFullEvent = remoteEvents:WaitForChild("CapacityFullEvent") -- NEW EVENT
local throwMemeEvent = remoteEvents:WaitForChild("ThrowMemeEvent")

-- Constants
local MAX_DISTANCE = 500 
local RELOAD_TIME = 0.8

local function calculateTrajectory(powerPercent, strength, rebirthMultiplier)
	local baseDistance = MAX_DISTANCE * powerPercent
	local finalDistance = baseDistance * strength * rebirthMultiplier
	local accuracy = powerPercent
	return finalDistance, accuracy
end

-- Function to find the brainrot model from any part within it
local function findBrainrotModel(part)
	local current = part.Parent
	for i = 1, 5 do
		if current and current:IsA("Model") and current:GetAttribute("Rarity") ~= nil then
			return current
		end
		if current then
			current = current.Parent
		else
			break
		end
	end
	return nil
end

-- Function to count how many brainrots player currently has
local function countPlayerBrainrots(player)
	local count = 0

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("Rarity") then
				count = count + 1
			end
		end
	end

	-- Check equipped tool
	if player.Character then
		local equippedTool = player.Character:FindFirstChildOfClass("Tool")
		if equippedTool and equippedTool:GetAttribute("Rarity") then
			count = count + 1
		end
	end

	return count
end


local function canCollectBrainrot(player, brainrotModel)
	local requirement = brainrotModel:GetAttribute("RebirthRequirement") or 0

	if requirement == 0 then
		return true -- Common brainrots always collectible
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false end

	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if not rebirths then return false end

	if rebirths.Value < requirement then
		-- Player doesn't have enough rebirths
		warn("?? " .. player.Name .. " needs " .. requirement .. " rebirths to collect this brainrot!")
		return false
	end

	return true
end






-- Function to convert brainrot model into a tool and add to player's inventory
local function collectBrainrot(player, brainrotModel)
	
	
	-- CHECK LOCK STATUS FIRST
	if not canCollectBrainrot(player, brainrotModel) then
		print("? " .. player.Name .. " cannot collect locked brainrot: " .. brainrotModel.Name)
		return false
	end
	-- Check capacity SECOND
	local currentCount = countPlayerBrainrots(player)
	local maxCapacity = player:GetAttribute("BrainrotCapacity") or 1

	if currentCount >= maxCapacity then
		print("? " .. player.Name .. " is at capacity (" .. currentCount .. "/" .. maxCapacity .. ")")

		-- [[ NEW FEATURE: FIRE CAPACITY GUI ]] --
		capacityFullEvent:FireClient(player)
		return false
	end

	local rarity = brainrotModel:GetAttribute("Rarity") or "Common"

	-- COPY THE MUTATION
	local mutation = brainrotModel:GetAttribute("Mutation")
	local mutationMult = brainrotModel:GetAttribute("MutationMult")

	-- Clone world model
	local clone = brainrotModel:Clone()
	clone.Parent = nil

	-- Gather BaseParts
	local parts = {}
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
		end
	end

	if #parts == 0 then
		warn("Brainrot has no BaseParts:", brainrotModel.Name)
		clone:Destroy()
		return false
	end

	-- Choose handle
	local handle = parts[1]
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanTouch = false

	-- Create Tool
	local tool = Instance.new("Tool")
	tool.Name = brainrotModel.Name
	tool.RequiresHandle = true
	tool.CanBeDropped = true
	tool:SetAttribute("Rarity", rarity)

	-- PASTE THE MUTATION
	if mutation then
		tool:SetAttribute("Mutation", mutation)
		if mutationMult then
			tool:SetAttribute("MutationMult", mutationMult)
		end
		print("? SAVED MUTATION: " .. mutation .. " on " .. tool.Name)
	end

	-- Parent handle
	handle.Parent = tool

	-- Weld remaining parts
	for _, part in ipairs(parts) do
		if part ~= handle then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.Parent = tool

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = handle
		end
	end

	-- Destroy leftover containers
	clone:Destroy()

	-- Give tool to player
	tool.Parent = player:WaitForChild("Backpack")

	-- Remove world instance
	brainrotModel:Destroy()

	local newCount = currentCount + 1
	print("? Brainrot added to Backpack:", tool.Name, "(" .. newCount .. "/" .. maxCapacity .. ")")
	return true
end

local function trackProjectile(player, projectile, detector, expectedDistance)
	local startPosition = projectile.Position
	local hoopsHit = {}
	local maxHeight = projectile.Position.Y
	local collectedBrainrots = {}

	-- TIME TRACKING VARIABLES
	local launchTime = os.clock()
	local groundHitTime = nil

	local heartbeatConnection
	local detectorConnection

	detectorConnection = detector.Touched:Connect(function(hit)
		if hit:IsDescendantOf(player.Character) then return end

		local currentTime = os.clock()

		-- Check for brainrot collision
		local brainrotModel = findBrainrotModel(hit)

		if brainrotModel then
			if not collectedBrainrots[brainrotModel] then

				-- Logic: Bounce vs Direct Hit
				local isBounce = false
				if groundHitTime ~= nil then
					local timeSinceGroundHit = currentTime - groundHitTime
					if timeSinceGroundHit > 0.15 then
						isBounce = true
					end
				end

				if isBounce then
					-- CASE 1: REAL BOUNCE (Notification ONLY)
					bounceNotificationEvent:FireClient(player) 
					print("Bounce Detected! (Notification sent)")
					collectedBrainrots[brainrotModel] = true
				else
					-- CASE 2: DIRECT HIT (Collect item)
					-- NOTE: collectBrainrot now handles the capacity check internally!
					local success = collectBrainrot(player, brainrotModel)

					-- If we successfully collected OR failed due to capacity, we mark it as processed
					-- so we don't trigger it again instantly
					collectedBrainrots[brainrotModel] = true
				end
			end
			return 
		end

		-- Check for hoop collision
		if hit.Name == "HoopPart" and hit.Parent and not hoopsHit[hit.Parent] then
			local hoop = hit.Parent
			local tier = hoop:FindFirstChild("Tier")
			if tier and tier:IsA("IntValue") then
				hoopsHit[hoop] = tier.Value
				hit.BrickColor = BrickColor.new("Bright green")
				task.delay(0.5, function()
					if hit then hit.BrickColor = BrickColor.new("Really red") end
				end)
			end
			return
		end

		-- Ground/Wall Detection
		if hit.CanCollide and hit.Name ~= "ProjectileDetector" then
			if groundHitTime == nil and (currentTime - launchTime > 0.1) then
				groundHitTime = currentTime
			end
		end
	end)

	-- Monitor projectile height and landing
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not projectile or not projectile.Parent then
			heartbeatConnection:Disconnect()
			if detectorConnection then detectorConnection:Disconnect() end
			return
		end

		if projectile.Position.Y > maxHeight then
			maxHeight = projectile.Position.Y
		end

		if projectile.Position.Y < -50 or projectile.AssemblyLinearVelocity.Magnitude < 1 then
			heartbeatConnection:Disconnect()
			if detectorConnection then detectorConnection:Disconnect() end

			local endPosition = projectile.Position
			local distanceTraveled = (endPosition - startPosition).Magnitude
			local moneyEarned = math.floor(distanceTraveled)

			if distanceTraveled > 5 then
				print("SERVER: " .. player.Name .. " threw " .. math.floor(distanceTraveled) .. " studs, earned $" .. moneyEarned)
			end

			task.wait(2)
			if detector then detector:Destroy() end
			if projectile then projectile:Destroy() end
		end
	end)
end

local function reloadTool(player, toolName)
	task.wait(RELOAD_TIME)
	local originalToolTemplate = StarterPack:FindFirstChild(toolName)
	if originalToolTemplate and player.Character then
		local newTool = originalToolTemplate:Clone()

		-- GET REBIRTH COUNT FOR SCALING
		local leaderstats = player:FindFirstChild("leaderstats")
		local rebirthCount = 0
		if leaderstats then
			local rebirths = leaderstats:FindFirstChild("Rebirths")
			if rebirths then
				rebirthCount = rebirths.Value
			end
		end

		-- Calculate scale for 2x volume per rebirth
		local volumeMultiplier = 1.5 ^ rebirthCount
		local scaleMultiplier = volumeMultiplier ^ (1/3)

		if rebirthCount > 0 then
			print("?? Scaling tool for " .. player.Name .. ": " .. string.format("%.2f", scaleMultiplier) .. "x (" .. volumeMultiplier .. "x volume)")

			-- Scale all parts in the tool
			for _, descendant in pairs(newTool:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Size = descendant.Size * scaleMultiplier
					-- IMPORTANT: Keep CanCollide false while held to prevent floor clipping
					descendant.CanCollide = false
					descendant.Massless = true
				elseif descendant:IsA("SpecialMesh") then
					descendant.Scale = descendant.Scale * scaleMultiplier
				end
			end
		else
			-- Make sure parts don't collide when held
			for _, descendant in pairs(newTool:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.CanCollide = false
					descendant.Massless = true
				end
			end
		end

		newTool.Parent = player.Backpack
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then humanoid:EquipTool(newTool) end
	else
		warn("Could not find tool " .. toolName .. " in StarterPack to reload!")
	end
end

local function launchProjectile(player, powerPercent, distance, accuracy, targetPosition)
	local character = player.Character
	if not character then return end

	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then return end

	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	local toolName = tool.Name
	local startPos = handle.Position

	local projectile = handle
	projectile.Parent = Workspace 
	projectile.Name = "MemeProjectile"
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.CanTouch = true
	
	-- In your ThrowingSystem, in the launchProjectile function:
	-- Right after you set projectile properties, add:

	local PhysicsService = game:GetService("PhysicsService")

	-- Assign projectile to Projectiles collision group
	PhysicsService:SetPartCollisionGroup(projectile, "Projectiles")

	-- Also assign the detector
	PhysicsService:SetPartCollisionGroup(detector, "Projectiles")

	-- GET REBIRTH COUNT FOR DETECTOR SCALING
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirthCount = 0
	if leaderstats then
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			rebirthCount = rebirths.Value
		end
	end

	-- Calculate detector scale (2x volume per rebirth)
	local volumeMultiplier = 2 ^ rebirthCount
	local detectorScale = volumeMultiplier ^ (1/3)

	-- Scale detector for collision detection
	local baseDetectorSize = 8
	local detectorSize = baseDetectorSize * detectorScale

	local detector = Instance.new("Part")
	detector.Name = "ProjectileDetector"
	detector.Size = Vector3.new(detectorSize, detectorSize, detectorSize) 
	detector.Transparency = 1
	detector.CanCollide = false
	detector.CanTouch = true
	detector.Massless = true
	detector.CFrame = projectile.CFrame
	detector.Parent = Workspace

	print("?? Detector size: " .. detectorSize .. " (" .. volumeMultiplier .. "x volume)")

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = projectile
	weld.Part1 = detector
	weld.Parent = projectile

	for _, child in pairs(projectile:GetChildren()) do
		if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Motor6D") then
			child:Destroy()
		end
	end

	tool:Destroy()

	local directionVector = (targetPosition - startPos).Unit
	local arcDirection = (directionVector + Vector3.new(0, 0.2, 0)).Unit
	local deviation = (1 - accuracy) * 0.3
	local randomWobble = Vector3.new(
		(math.random() - 0.5) * deviation,
		(math.random() - 0.5) * deviation,
		(math.random() - 0.5) * deviation
	)

	local finalDirection = (arcDirection + randomWobble).Unit
	local speed = 50 + (powerPercent * 150) 
	local velocity = finalDirection * speed

	projectile.AssemblyLinearVelocity = velocity
	projectile:SetNetworkOwner(nil)

	trackProjectile(player, projectile, detector, distance)

	task.spawn(function() 
		reloadTool(player, toolName)
	end)
end

local function launchProjectile(player, powerPercent, distance, accuracy, targetPosition)
	local character = player.Character
	if not character then return end

	local tool = character:FindFirstChildOfClass("Tool") -- FIXED: was "Banana"
	if not tool then return end

	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	local toolName = tool.Name
	local startPos = handle.Position

	local projectile = handle
	projectile.Parent = Workspace 
	projectile.Name = "MemeProjectile"
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.CanTouch = true

	local detector = Instance.new("Part")
	detector.Name = "ProjectileDetector"
	detector.Size = Vector3.new(8, 8, 8) 
	detector.Transparency = 1
	detector.CanCollide = false
	detector.CanTouch = true
	detector.Massless = true
	detector.CFrame = projectile.CFrame
	detector.Parent = Workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = projectile
	weld.Part1 = detector
	weld.Parent = projectile

	for _, child in pairs(projectile:GetChildren()) do
		if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Motor6D") then
			child:Destroy()
		end
	end

	tool:Destroy()

	local directionVector = (targetPosition - startPos).Unit
	local arcDirection = (directionVector + Vector3.new(0, 0.2, 0)).Unit
	local deviation = (1 - accuracy) * 0.3
	local randomWobble = Vector3.new(
		(math.random() - 0.5) * deviation,
		(math.random() - 0.5) * deviation,
		(math.random() - 0.5) * deviation
	)

	local finalDirection = (arcDirection + randomWobble).Unit
	local speed = 50 + (powerPercent * 150) 
	local velocity = finalDirection * speed

	projectile.AssemblyLinearVelocity = velocity
	projectile:SetNetworkOwner(nil)

	trackProjectile(player, projectile, detector, distance)

	task.spawn(function() 
		reloadTool(player, toolName)
	end)
end

throwMemeEvent.OnServerEvent:Connect(function(player, powerPercent, targetPosition)
	if type(powerPercent) ~= "number" then return end
	if typeof(targetPosition) ~= "Vector3" then
		if player.Character and player.Character.PrimaryPart then
			targetPosition = player.Character.PrimaryPart.Position + (player.Character.PrimaryPart.CFrame.LookVector * 50)
		else
			return 
		end
	end
	local strength = 1
	local rebirthMultiplier = 1
	local distance, accuracy = calculateTrajectory(powerPercent, strength, rebirthMultiplier)
	launchProjectile(player, powerPercent, distance, accuracy, targetPosition)
end)

print("ThrowingSystem loaded!")