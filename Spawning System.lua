local replicatedstorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService") -- ADDED

local brainrotsfolder = replicatedstorage:FindFirstChild("Brainrot pack1") or replicatedstorage:WaitForChild("Brainrot pack1")
local brainrots = brainrotsfolder:GetChildren()
local WeatherSystem = require(game.ReplicatedStorage:WaitForChild("WeatherSystem"))

-- Wait for collision groups to be set up
repeat task.wait(0.1) until pcall(function() 
	PhysicsService:GetCollisionGroupId("NPCs") 
end)
print("✅ Collision groups detected, spawning system ready")

-- Rebirth requirements for each rarity
local RARITY_REQUIREMENTS = {
	["Common"] = 0,
	["Rare"] = 1,
	["Epic"] = 3,
	["Legendary"] = 5,
	["Mythic"] = 10,
	["Brainrot God"] = 25,
	["Secret"] = 50,
	["OG"] = 100,
}

-- Ensure RemoteEvents exist
local Remotes = game.ReplicatedStorage:FindFirstChild("RemoteEvents")
if not Remotes then
	Remotes = Instance.new("Folder", game.ReplicatedStorage)
	Remotes.Name = "RemoteEvents"
end

local function getRemote(name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent", Remotes)
		r.Name = name
	end
	return r
end

local Remotes            = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local event              = Remotes:WaitForChild("randombrainrot")
local autospawn          = Remotes:WaitForChild("AutoSpawn")
local spawnSpecificEvent = Remotes:WaitForChild("SpawnSpecificBrainrot")

local PLATFORM_CENTER_X = 0
local PLATFORM_CENTER_Z = 0
local PLATFORM_RADIUS = 120
local PLATFORM_Y = 1

local AUTO_SPAWN_ENABLED = true
local AUTO_SPAWN_INTERVAL = 3 
local DESPAWN_TIME = {
	["Common"] = 120, ["Rare"] = 120, ["Epic"] = 120, ["Legendary"] = 120,
	["Mythic"] = 120, ["Secret"] = 120, ["OG"] = 120, ["Brainrot God"] = 120,
}
local MAX_BRAINROTS = 25 

local activeBrainrots = {}

local RARITY_COLORS = {
	["Common"] = Color3.fromRGB(0, 255, 0),
	["Rare"] = Color3.fromRGB(0, 100, 255),
	["Epic"] = Color3.fromRGB(150, 0, 255),
	["Legendary"] = Color3.fromRGB(255, 255, 0),
	["Mythic"] = Color3.fromRGB(255, 0, 0),
	["Brainrot God"] = "Rainbow",
	["Secret"] = Color3.fromRGB(30, 30, 30),
	["OG"] = "Split",
}

local MUTATION_COLORS = {
	-- Permanent
	["Gold"]        = Color3.fromRGB(255, 215, 0),
	["Diamond"]     = Color3.fromRGB(185, 242, 255),
	["Rainbow"]     = "Rainbow",
	-- Limited (weather-gated)
	["Bloodrot"]    = Color3.fromRGB(100, 0, 0),
	["Candy"]       = Color3.fromRGB(255, 105, 180),
	["Lava"]        = Color3.fromRGB(255, 80, 0),
	["Galaxy"]      = Color3.fromRGB(138, 43, 226),
	["Yin-Yang"]    = "YinYang",
	["Radioactive"] = Color3.fromRGB(0, 255, 50),
	["Wet"] = Color3.fromRGB(84, 130, 255)
}

local MUTATION_RATES = {
	-- Permanent mutations — always in the pool
	["Rainbow"]  = 5,
	["Diamond"]  = 102,
	["Gold"]     = 250,
	-- Limited mutations — 0 base rate; boosted by weather system
	["Bloodrot"]    = 0,
	["Candy"]       = 0,
	["Lava"]        = 0,
	["Galaxy"]      = 0,
	["Yin-Yang"]    = 0,
	["Radioactive"] = 0,
	["Wet"] = 0
}

local MUTATION_MULTIPLIERS = {
	-- Permanent
	["Gold"]        = 1.25,
	["Diamond"]     = 1.50,
	["Rainbow"]     = 10.0,
	-- Limited
	["Bloodrot"]    = 2.0,
	["Candy"]       = 4.0,
	["Lava"]        = 6.0,
	["Galaxy"]      = 7.0,
	["Yin-Yang"]    = 7.5,
	["Radioactive"] = 8.5,
	["Wet"] = 1.5
}

local RARITY_SPEEDS = {
	["Common"] = 24, 
	["Rare"] = 36, 
	["Epic"] = 48, 
	["Legendary"] = 60,
	["Mythic"] = 75, 
	["Brainrot God"] = 90,
	["BrainrotGod"] = 90,
	["Secret"] = 100, 
	["OG"] = 150,
}

local function getValidSpawnPosition()
	local x = math.random(-256, 256)
	local z = math.random(-256, 256)
	return Vector3.new(x, PLATFORM_Y + 5, z)
end

local function getMutation()
	local roll = math.random(1, 1000)
	if roll <= MUTATION_RATES["Rainbow"] then
		return "Rainbow"
	elseif roll <= MUTATION_RATES["Rainbow"] + MUTATION_RATES["Diamond"] then
		return "Diamond"
	elseif roll <= MUTATION_RATES["Rainbow"] + MUTATION_RATES["Diamond"] + MUTATION_RATES["Gold"] then
		return "Gold"
	end
	return nil
end

local function animateRainbow(textLabel)
	task.spawn(function()
		local hue = 0
		while textLabel and textLabel.Parent do
			hue = (hue + 0.01) % 1
			textLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
			task.wait(0.05)
		end
	end)
end

local function animateRainbowModel(model)
	task.spawn(function()
		local hue = 0
		local parts = {}
		for _, descendant in pairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then table.insert(parts, descendant) end
		end
		while model and model.Parent do
			hue = (hue + 0.01) % 1
			local rainbowColor = Color3.fromHSV(hue, 1, 1)
			for _, part in pairs(parts) do
				if part and part.Parent then 
					part.Color = rainbowColor 
				end
			end
			task.wait(0.05)
		end
	end)
end

local function applyMonochromeFilter(brainrotModel)
	for _, descendant in pairs(brainrotModel:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
			local originalColor = descendant.Color
			local gray = (originalColor.R + originalColor.G + originalColor.B) / 3
			descendant.Color = Color3.new(gray, gray, gray)
			descendant.Material = Enum.Material.SmoothPlastic

			local surfaceAppearance = descendant:FindFirstChildOfClass("SurfaceAppearance")
			if surfaceAppearance then
				surfaceAppearance:Destroy()
			end
		elseif descendant:IsA("SpecialMesh") then
			descendant.TextureId = ""
		end
	end
end

local function applyMutationVisuals(brainrotModel, mutation)
	if not mutation then return end

	local function applyColorToPart(part, color, material, reflectance)
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.Color = color
			if material then part.Material = material end
			if reflectance then part.Reflectance = reflectance end

			local surfaceAppearance = part:FindFirstChildOfClass("SurfaceAppearance")
			if surfaceAppearance then
				surfaceAppearance:Destroy()
			end
		end
	end

	if mutation == "Rainbow" then
		animateRainbowModel(brainrotModel)
		for _, descendant in pairs(brainrotModel:GetDescendants()) do
			if descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
				local surfaceAppearance = descendant:FindFirstChildOfClass("SurfaceAppearance")
				if surfaceAppearance then
					surfaceAppearance:Destroy()
				end
			end
		end
	elseif mutation == "Gold" then
		for _, descendant in pairs(brainrotModel:GetDescendants()) do
			applyColorToPart(descendant, Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, nil)
			if descendant:IsA("SpecialMesh") then
				descendant.TextureId = ""
			end
		end
	elseif mutation == "Diamond" then
		for _, descendant in pairs(brainrotModel:GetDescendants()) do
			applyColorToPart(descendant, Color3.fromRGB(185, 242, 255), Enum.Material.SmoothPlastic, 0.3)
			if descendant:IsA("SpecialMesh") then
				descendant.TextureId = ""
			end
		end
	end
end

local function animateGalaxy(model)
	task.spawn(function()
		local parts = {}
		for _, d in pairs(model:GetDescendants()) do
			if d:IsA("BasePart") then table.insert(parts, d) end
		end
		local t = 0
		while model and model.Parent do
			t += 0.02
			local brightness = 0.5 + 0.5 * math.sin(t)
			local col = Color3.fromRGB(
				math.floor(75  + 63  * brightness),
				math.floor(0   + 0   * brightness),
				math.floor(130 + 100 * brightness)
			)
			for _, p in pairs(parts) do
				if p and p.Parent then p.Color = col end
			end
			task.wait(0.05)
		end
	end)
end

local function animateYinYang(model)
	task.spawn(function()
		local parts = {}
		for _, d in pairs(model:GetDescendants()) do
			if d:IsA("BasePart") then table.insert(parts, d) end
		end
		local flip = false
		local timer = 0
		while model and model.Parent do
			timer += 0.05
			if timer >= 0.5 then
				timer = 0
				flip = not flip
				local col = flip and Color3.new(1,1,1) or Color3.new(0,0,0)
				for _, p in pairs(parts) do
					if p and p.Parent then p.Color = col end
				end
			end
			task.wait(0.05)
		end
	end)
end

local function animateRadioactive(model)
	task.spawn(function()
		local parts = {}
		for _, d in pairs(model:GetDescendants()) do
			if d:IsA("BasePart") then table.insert(parts, d) end
		end
		local t = 0
		while model and model.Parent do
			t += 0.08
			local brightness = 0.5 + 0.5 * math.sin(t)
			local g = math.floor(150 + 105 * brightness)
			local col = Color3.fromRGB(0, g, 0)
			for _, p in pairs(parts) do
				if p and p.Parent then p.Color = col end
			end
			task.wait(0.05)
		end
	end)
end

local function applyLimitedMutationVisuals(brainrotModel, mutation)
	if not mutation then return end
	local visualData = WeatherSystem.LIMITED_VISUALS[mutation]
	if not visualData then return end

	for _, d in pairs(brainrotModel:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("MeshPart") then
			local sa = d:FindFirstChildOfClass("SurfaceAppearance")
			if sa then sa:Destroy() end
			if visualData.material then
				d.Material = visualData.material
			end
			if visualData.reflectance then
				d.Reflectance = visualData.reflectance
			end
			if visualData.color and visualData.animated == false then
				d.Color = visualData.color
			end
		elseif d:IsA("SpecialMesh") then
			d.TextureId = ""
		end
	end

	if visualData.animated == "galaxy" then
		animateGalaxy(brainrotModel)
	elseif visualData.animated == "yinyang" then
		animateYinYang(brainrotModel)
	elseif visualData.animated == "radioactive" then
		animateRadioactive(brainrotModel)
	end
end

local function addNameTag(brainrot)
	local rarity = brainrot:GetAttribute("Rarity") or "Common"
	local mutation = brainrot:GetAttribute("Mutation")
	local isLocked = brainrot:GetAttribute("IsLocked") or false
	local anchorPart = brainrot:FindFirstChild("RootPart") or brainrot.PrimaryPart or brainrot:FindFirstChildWhichIsA("BasePart")

	if not anchorPart then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "StatsGUI"
	bb.Adornee = anchorPart
	bb.Size = UDim2.new(12, 0, 6, 0)
	bb.ExtentsOffset = Vector3.new(0, 2.5, 0) 
	bb.AlwaysOnTop = true
	bb.MaxDistance = 400 
	bb.Parent = brainrot

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = bb

	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = container
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.Padding = UDim.new(0, 0)

	local function createLabel(text, layoutOrder, font, color, strokeColor, strokeTrans)
		local lbl = Instance.new("TextLabel")
		lbl.Text = text
		lbl.Size = UDim2.new(1, 0, 0.2, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextScaled = true
		lbl.Font = font
		lbl.TextColor3 = color
		lbl.TextStrokeColor3 = strokeColor or Color3.new(0,0,0)
		lbl.TextStrokeTransparency = strokeTrans or 0.5
		lbl.LayoutOrder = layoutOrder
		lbl.Parent = container

		local constraint = Instance.new("UITextSizeConstraint")
		constraint.MaxTextSize = 35 
		constraint.MinTextSize = 2  
		constraint.Parent = lbl

		return lbl
	end

	if isLocked then
		createLabel("🔒 LOCKED", 0, Enum.Font.FredokaOne, Color3.fromRGB(255, 50, 50))
	end

	local maxDuration = DESPAWN_TIME[rarity] or 60
	local tLabel = createLabel("⏳ " .. maxDuration .. "s", 1, Enum.Font.FredokaOne, Color3.new(1,1,1), Color3.new(0,0,0), 0)

	if mutation then
		local mutText = "⭐ " .. mutation .. " ⭐"
		local mutColor = Color3.new(1,1,1)
		local mc = MUTATION_COLORS[mutation]
		if mc and mc ~= "Rainbow" then mutColor = mc end

		local mLabel = createLabel(mutText, 2, Enum.Font.SourceSansBold, mutColor, Color3.new(0,0,0), 0)

		-- 👇 ADD THIS LINE SO THE WEATHER SYSTEM CAN FIND IT! 👇
		mLabel.Name = "MutationLabel"

		if mutation and MUTATION_COLORS[mutation] == "Rainbow" then
			animateRainbow(mLabel)
		end
	end

	local rarityColor = RARITY_COLORS[rarity] or Color3.new(1,1,1)
	local nameColor = Color3.new(1,1,1)

	if rarityColor == "Rainbow" or rarityColor == "Split" then
		nameColor = Color3.new(1,1,1)
	elseif typeof(rarityColor) == "Color3" then
		nameColor = rarityColor
	end

	local nLabel = createLabel(brainrot.Name, 3, Enum.Font.SourceSansBold, nameColor)
	if rarityColor == "Rainbow" then 
		animateRainbow(nLabel) 
	end

	local rarityTextColor = Color3.new(1,1,1)

	if rarityColor == "Rainbow" then
		rarityTextColor = Color3.new(1,1,1)
	elseif rarityColor == "Split" then
		rarityTextColor = Color3.new(1,0,0)
	elseif typeof(rarityColor) == "Color3" then
		rarityTextColor = rarityColor
	end

	local rLabel = createLabel(rarity, 4, Enum.Font.SourceSansBold, rarityTextColor)

	if rarityColor == "Rainbow" then
		animateRainbow(rLabel)
	elseif rarityColor == "Split" then
		nLabel.TextColor3 = Color3.new(0,1,0)
		rLabel.TextColor3 = Color3.new(1,0,0) 
	end

	task.spawn(function()
		local startTime = os.time()
		local lastTimeLeft = maxDuration 

		while brainrot and brainrot.Parent do
			local elapsed = os.time() - startTime
			local timeLeft = maxDuration - elapsed
			if timeLeft < 0 then timeLeft = 0 end

			if timeLeft ~= lastTimeLeft then
				tLabel.Text = "⏳ " .. timeLeft .. "s"
				lastTimeLeft = timeLeft

				if timeLeft <= 10 then
					tLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
				else
					tLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end

			if timeLeft <= 0 then break end
			task.wait(0.1)
		end
	end)
end

local function enableCollisionDetection(brainrot)
	local rootPart = brainrot:FindFirstChild("RootPart") or brainrot.PrimaryPart or brainrot:FindFirstChildWhichIsA("BasePart")
	if not rootPart then
		warn("⚠️ No RootPart found for " .. brainrot.Name)
		return
	end

	for _, descendant in pairs(brainrot:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanTouch = true

			-- ADDED: Assign to NPCs collision group
			PhysicsService:SetPartCollisionGroup(descendant, "NPCs")

			if descendant ~= rootPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = rootPart
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end
end

local function makeBrainrotWander(brainrot, speed)
	task.spawn(function()
		local rootPart = brainrot:FindFirstChild("RootPart") or brainrot.PrimaryPart
		if not rootPart then return end

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.Parent = rootPart

		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(500000, 500000, 500000) 
		bodyGyro.P = 25000 
		bodyGyro.D = 1000  
		bodyGyro.Parent = rootPart

		local WADDLE_SPEED = 18    
		local WADDLE_AMOUNT = 0.3 

		while brainrot and brainrot.Parent do
			local randomAngle = math.random() * math.pi * 2
			local randomDistance = math.random(30, 80)

			local currentPos = rootPart.Position
			local offsetX = math.cos(randomAngle) * randomDistance
			local offsetZ = math.sin(randomAngle) * randomDistance

			local destinationX = currentPos.X + offsetX
			local destinationZ = currentPos.Z + offsetZ

			local destDX = destinationX - PLATFORM_CENTER_X
			local destDZ = destinationZ - PLATFORM_CENTER_Z
			local destDistance = math.sqrt(destDX * destDX + destDZ * destDZ)

			if destDistance > (PLATFORM_RADIUS - 15) then
				destinationX = currentPos.X - offsetX
				destinationZ = currentPos.Z - offsetZ
			end

			local destination = Vector3.new(destinationX, PLATFORM_Y + 3, destinationZ)
			local moveDuration = randomDistance / speed
			local startTime = tick()

			while tick() - startTime < moveDuration and brainrot and brainrot.Parent do
				currentPos = rootPart.Position
				local direction = (destination - currentPos) * Vector3.new(1, 0, 1)

				if direction.Magnitude > 3 then
					direction = direction.Unit * speed
					bodyVelocity.Velocity = Vector3.new(direction.X, 0, direction.Z)

					local currentTime = tick()
					local wobbleZ = math.sin(currentTime * WADDLE_SPEED) * WADDLE_AMOUNT
					local lookPos = currentPos + direction
					local baseCFrame = CFrame.new(currentPos, Vector3.new(lookPos.X, currentPos.Y, lookPos.Z))

					bodyGyro.CFrame = baseCFrame * CFrame.Angles(-0.1, 0, wobbleZ)
				else
					break 
				end
				task.wait(0.05)
			end
		end
	end)
end

local function removeBrainrot(brainrot)
	for i, tracked in ipairs(activeBrainrots) do
		if tracked == brainrot then
			table.remove(activeBrainrots, i)
			break
		end
	end
	if brainrot and brainrot.Parent then brainrot:Destroy() end
end

local function scheduleDespawn(brainrot)
	local rarity = brainrot:GetAttribute("Rarity") or "Common"
	local waitTime = DESPAWN_TIME[rarity] or 60
	task.delay(waitTime, function() removeBrainrot(brainrot) end)
end

local function spawnbrainrot()
	if #activeBrainrots >= MAX_BRAINROTS then
		print("⚠️ Brainrot cap reached (" .. MAX_BRAINROTS .. "), skipping spawn")
		return
	end

	local basicrarity = "Common"
	local randomnum = math.random(1, 1000000)
	if randomnum <= 850000  then basicrarity = "Common"
	elseif randomnum <= 950000 then basicrarity = "Rare"
	elseif randomnum <= 975000  then basicrarity = "Epic"
	elseif randomnum <=990000 then basicrarity = "Legendary"
	elseif randomnum <= 999000 then basicrarity = "Mythic"
	elseif randomnum <= 999900 then basicrarity = "Brainrot God"
	elseif randomnum <= 9999900 then basicrarity = "Secret"
	else basicrarity = "OG" end

	local validbrainrotlist = {}
	for i, brainrot in pairs(brainrots) do
		if brainrot:GetAttribute("Rarity") == basicrarity then
			table.insert(validbrainrotlist, brainrot)
		end
	end

	if #validbrainrotlist == 0 then return end 

	local brainrot = validbrainrotlist[math.random(1, #validbrainrotlist)]:Clone()

	local mutation = getMutation()
	if mutation then
		brainrot:SetAttribute("Mutation", mutation)
		brainrot:SetAttribute("MutationMult",MUTATION_MULTIPLIERS[mutation])
	end

	local requirement = RARITY_REQUIREMENTS[basicrarity] or 0
	brainrot:SetAttribute("RebirthRequirement", requirement)
	brainrot:SetAttribute("IsLocked", false)

	local spawnPosition = getValidSpawnPosition()
	if brainrot:IsA("Model") then
		brainrot:PivotTo(CFrame.new(spawnPosition))
	else
		brainrot.Position = spawnPosition
	end

	brainrot.Parent = workspace
	table.insert(activeBrainrots, brainrot)

	enableCollisionDetection(brainrot)

	if mutation then
		local limited = WeatherSystem.LIMITED_VISUALS[mutation]
		if limited then
			applyLimitedMutationVisuals(brainrot, mutation)
		else
			applyMutationVisuals(brainrot, mutation)
		end
	end

	addNameTag(brainrot)

	local rarity = brainrot:GetAttribute("Rarity")
	local speed = RARITY_SPEEDS[rarity]

	if not speed then
		warn("⚠️ Unknown rarity '" .. tostring(rarity) .. "' for " .. brainrot.Name .. " - using default speed of 24")
		speed = 24
	end

	print("🐌 Speed for " .. brainrot.Name .. " (Rarity: '" .. rarity .. "'): " .. speed)

	makeBrainrotWander(brainrot, speed)
	scheduleDespawn(brainrot)
	print("🎯 Spawned: " .. brainrot.Name .. " (" .. basicrarity .. ")" .. (requirement > 0 and " 🔒" or ""))
end

event.OnServerEvent:Connect(spawnbrainrot)

local function isDeveloper(player)
	if RunService:IsStudio() then return true end
	return player.UserId == game.CreatorId or player.UserId == 10378926133
end

spawnSpecificEvent.OnServerEvent:Connect(function(player, brainrotName)
	if not isDeveloper(player) then return end
	if #activeBrainrots >= MAX_BRAINROTS then return end

	for _, brainrot in pairs(brainrots) do
		if brainrot.Name:lower() == brainrotName:lower() then
			local clone = brainrot:Clone()
			local mutation = getMutation()
			if mutation then clone:SetAttribute("Mutation", mutation) end

			local rarity = clone:GetAttribute("Rarity") or "Common"
			local requirement = RARITY_REQUIREMENTS[rarity] or 0
			clone:SetAttribute("RebirthRequirement", requirement)
			clone:SetAttribute("IsLocked", requirement > 0)

			local spawnPosition = getValidSpawnPosition()
			if clone:IsA("Model") then clone:PivotTo(CFrame.new(spawnPosition))
			else clone.Position = spawnPosition end

			clone.Parent = workspace
			table.insert(activeBrainrots, clone)
			enableCollisionDetection(clone)

			if clone:GetAttribute("IsLocked") then
				applyMonochromeFilter(clone)
			elseif mutation then
				applyMutationVisuals(clone, mutation)
			end

			addNameTag(clone)

			local speed = RARITY_SPEEDS[rarity] or 8
			makeBrainrotWander(clone, speed)
			scheduleDespawn(clone)
			return
		end
	end
end)

if AUTO_SPAWN_ENABLED then
	task.spawn(function()
		print("🔄 Auto-spawn system started!")
		while true do
			task.wait(AUTO_SPAWN_INTERVAL)
			spawnbrainrot()
		end
	end)
end

print("✅ Spawning System loaded with auto-spawn, rebirth locks, and collision groups!")
