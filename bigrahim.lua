-- ServerScriptService/BrainrotSlotSystem
print("?? BrainrotSlotSystem starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local MutationHandler = require(ReplicatedStorage:WaitForChild("MutationHandler"))

-- Validate tools against this folder
local BrainrotPackFolder = ReplicatedStorage:WaitForChild("Brainrot pack1", 10)
if not BrainrotPackFolder then
	warn("CRITICAL: 'Brainrot pack1' folder not found in ReplicatedStorage!")
end
local economyevent = game.ReplicatedStorage.RemoteEvents.EconomyEvent
-- ==========================================================
-- CONFIG
-- ==========================================================
local BASES_FOLDER_NAME = "BrainrotBases"
local TweenService = game:GetService("TweenService")
-- Rarity colours  same as spawning system
local RARITY_COLORS = {
	["Common"]       = Color3.fromRGB(0, 255, 0),
	["Rare"]         = Color3.fromRGB(0, 100, 255),
	["Epic"]         = Color3.fromRGB(150, 0, 255),
	["Legendary"]    = Color3.fromRGB(255, 255, 0),
	["Mythic"]       = Color3.fromRGB(255, 0, 0),
	["Brainrot God"] = "Rainbow",
	["Secret"]       = Color3.fromRGB(0, 0, 0),
	["OG"]           = "Split",
}

-- Mutation colors/multipliers (centralized in MutationHandler)
local MUTATION_COLORS = {}
local MUTATION_MULTIPLIERS = {}
for mutationName, definition in pairs(MutationHandler.MUTATIONS) do
	MUTATION_COLORS[mutationName] = definition.color
	MUTATION_MULTIPLIERS[mutationName] = definition.multiplier
end

-- Income per second keyed by exact tool name (codev's table  most complete)
local BRAINROT_INCOME = {
	-- COMMON
	["Noobini Pizzanini"] = 1,
	["Lirili Larila"] = 3,
	["Tim Cheese"] = 5,
	["FluriFlura"] = 7,
	["Talpa Di Fero"] = 9,
	["Svinina Bombardino"] = 10,
	["Noobini Santanini"] = 11,
	["Racooni Jandelini"] = 12,
	["Pipi Kiwi"] = 13,
	["Tartaragno"] = 13,
	["Pipi Corni"] = 14,
	["Trippi Troppi"] = 15,
	["Gangster Footera"] = 30,
	["Bandito Bobritto"] = 35,
	["Boneca Ambalabu"] = 40,
	["Cacto Hipopotamo"] = 50,
	["Ta Ta Ta Ta Sahur"] = 55,
	["Tric Trac Baraboom"] = 65,
	["Frogo Elfo"] = 67,
	["Pipi Avocado"] = 70,
	["Pinealotto Fruttarino"] = 75,
	["Cappuccino Assassino"] = 75,
	["Bandito Axolito"] = 90,
	["Brr Brr Patapim"] = 100,
	["Avocadini Antilopini"] = 115,
	["Trulimero Trulicina"] = 125,
	["Bambini Crostini"] = 135,
	["Malame Amarele"] = 140,
	["Bananita Dolphinita"] = 150,
	["Perochello Lemonchello"] = 160,
	["Brri Brri Bicus Dicus Bombicus"] = 175,
	["Avocadini Guffo"] = 225,
	["Ti Ti Ti Sahur"] = 225,
	["Mangolini Parrocini"] = 235,
	["Frogatto Piratto"] = 240,
	["Salamino Penguino"] = 250,
	["Doi Doi Do"] = 260,
	["Penguin Tree"] = 270,
	["Wombo Rollo"] = 275,
	["Penguino Cocosino"] = 300,
	["Mummio Rappito"] = 325,
	["Chimpanzini Bananini"] = 300,
	["Tirilikalika Tirilikalako"] = 450,
	["Ballerina Cappuccina"] = 500,
	["Burbaloni Loliloli"] = 600,
	["Chef Crabracadabra"] = 600,
	["Lionel Cactuseli"] = 650,
	["Glorbo Fruttodrillo"] = 750,
	["Quivoli Ameleoni"] = 900,
	["Blueberrini Octopusini"] = 1000,
	["Caramello Filtrello"] = 1000,
	["Pipi Potato"] = 1100,
	["Strawberrelli Flamingelli"] = 1100,
	["Cocosini Mama"] = 1200,
	["Pandaccini Bananini"] = 1250,
	["Quackula"] = 1200,
	["Pi Pi Watermelon"] = 1300,
	["Signore Carapace"] = 1300,
	["Sigma Boy"] = 1350,
	["Chocco Bunny"] = 1400,
	["Puffaball"] = 1500,
	["Sigma Girl"] = 1800,
	["Buho de Fuego"] = 1800,
	["Frigo Camelo"] = 1900,
	["Orangutini Ananassini"] = 2000,
	["Rhino Toasterino"] = 2100,
	["Bombardiro Crocodilo"] = 2500,
	["Spioniro Golubiro"] = 3500,
	["Bangangini Gusini"] = 5000,
	["Zibra Zubra Zibralini"] = 6000,
	["Tigrilini Watermelini"] = 6500,
	["Avocadorilla"] = 7000,
	["Cavallo Virtuoso"] = 7500,
	["Gorillo Subwoofero"] = 7700,
	["Gorillo Watermelondrillo"] = 8000,
	["Stoppo Luminino"] = 8000,
	["Ganganzelli Trulala"] = 9000,
	["Lerulerulerule"] = 8700,
	["Tob Tobi Tobi"] = 8500,
	["Te Te Te Sahur"] = 9500,
	["Rhino Helicopterino"] = 11000,
	["Magi Ribbitini"] = 11500,
	["Tracoducotulu Delapeladustuz"] = 12000,
	["Jingle Jingle Sahur"] = 12200,
	["Los Noobinis"] = 12500,
	["Cachorrito Melonito"] = 13000,
	["Carloo"] = 13500,
	["Elefanto Frigo"] = 14000,
	["Carrotini Brainini"] = 15000,
	["Centrucci Nuclucci"] = 15500,
	["Jacko Spaventosa"] = 16200,
	["Toiletto Focaccino"] = 16000,
	["Bananito Bandito"] = 16500,
	["Tree Tree Tree Sahur"] = 17000,
	["Cocofanto Elefanto"] = 17500,
	["Antonio"] = 18500,
	["Girafa Celestre"] = 20000,
	["Gattatino Neonino"] = 35000,
	["Gattatino Nyanino"] = 35000,
	["Chihuanini Taconini"] = 45000,
	["Matteo"] = 50000,
	["Tralalero Tralala"] = 50000,
	["Los Crocodillitos"] = 55000,
	["Tigroligre Frutonni"] = 60000,
	["Espresso Signora"] = 70000,
	["Odin Din Din Dun"] = 75000,
	["Statutino Libertino"] = 75000,
	["Tipi Topi Taco"] = 75000,
	["Alessio"] = 85000,
	["Tralalita Tralala"] = 100000,
	["Tukanno Bananno"] = 100000,
	["Orcalero Orcala"] = 100000,
	["Extinct Ballerina"] = 125000,
	["Trenostruzzo Turbo 3000"] = 150000,
	["Urubini Flamenguini"] = 150000,
	["Capi Taco"] = 155000,
	["Gattito Tacoto"] = 160000,
	["Trippi Troppi Troppa Trippa"] = 175000,
	["Ballerino Lololo"] = 200000,
	["Bulbito Bandito Traktorito"] = 205000,
	["Los Tungtungtungcitos"] = 210000,
	["Ballerina Peppermintina"] = 215000,
	["Pakrahmatmamat"] = 215000,
	["Los Bombinitos"] = 220000,
	["Bombardini Tortinii"] = 225000,
	["Piccione Macchina"] = 225000,
	["Brr es Teh Patipum"] = 225000,
	["Tractoro Dinosauro"] = 230000,
	["Los Orcalitos"] = 235000,
	["Corn Corn Corn Sahur"] = 250000,
	["Squalanana"] = 250000,
	["Dug Dug Dug"] = 255000,
	["Yeti Claus"] = 257500,
	["Ginger Globo"] = 257500,
	["Los Tipi Tacos"] = 260000,
	["Frio Ninja"] = 265000,
	["Ginger Cisterna"] = 293500,
	["Pop Pop Sahur"] = 295000,
	["La Vacca Saturno Saturnita"] = 300000,
	["Los Matteos"] = 300000,
	["Bisonte Giuppitere"] = 300000,
	["Jackorilla"] = 315000,
	["Sammyni Spyderini"] = 325000,
	["Chimpanzini Spiderini"] = 325000,
	["Torrtuginni Dragonfrutini"] = 350000,
	["Unclito Samito"] = 350000,
	["Dul Dul Dul"] = 375000,
	["Blackhole Goat"] = 400000,
	["Chachechi"] = 400000,
	["Guerriro Digitale"] = 425000,
	["Agarrini la Palini"] = 425000,
	["Extinct Tralalero"] = 450000,
	["Fragola La La La"] = 450000,
	["Los Spyderinis"] = 450000,
	["La Cucaracha"] = 475000,
	["Los Tortus"] = 500000,
	["Los Tralaleritos"] = 750000,
	["Extinct Matteo"] = 500000,
	["Vulturino Skeletono"] = 500000,
	["Boatito Auratito"] = 525000,
	["Karkerkar Kurkur"] = 550000,
	["Orcalita Orcala"] = 575000,
	["Piccionetta Macchina"] = 600000,
	["Las Tralaleritas"] = 650000,
	["Job Job Job Sahur"] = 700000,
	["Las Vaquitas Saturnitas"] = 750000,
	["Los Combinasionas"] = 800000,
	["Trenzostruzzo Turbo 4000"] = 850000,
	["La Grande Combinasion"] = 10000000,
	["Graipuss Medussi"] = 1000000,
	["Anpali Babel"] = 1200000,
	["Mastodontico Telepiedone"] = 1200000,
	["Noo My Hotspot"] = 1500000,
	["La Sahur Combinasion"] = 2000000,
	["Nooo My Hotspot"] = 2000000,
	["La Karkerkar Combinasion"] = 17500000,
	["Pot Hotspot"] = 2500000,
	["Esok Sekolah"] = 3000000,
	["Chicleteira Bicicleteira"] = 3500000,
	["67"] = 7500000,
	["Los Nooo My Hotspotsitos"] = 5500000,
	["Nuclearo Dinossauro"] = 15000000,
	["Las Sis"] = 17500000,
	["Celularcini Viciosini"] = 22500000,
	["Los Bros"] = 24000000,
	["Tralaledon"] = 27500000,
	["La Esok Sekolah"] = 30000000,
	["Tang Tang Kelentang"] = 33500000,
	["Ketupat Kepat"] = 35000000,
	["Tictac Sahur"] = 37500000,
	["La Secret Combinasion"] = 125000000,
	["Ketchuru and Musturu"] = 42500000,
	["Garama and Madundung"] = 50000000,
	["Spaghetti Tualetti"] = 60000000,
	["Los Orcaleritos"] = 235000000,
	["Dragon Cannelloni"] = 200000000,
	-- OG
	["Strawberry Elephant"] = 350000000,
}

-- ==========================================================
-- SETUP
-- ==========================================================
local BASES_FOLDER = Workspace:WaitForChild(BASES_FOLDER_NAME, 5)
if not BASES_FOLDER then
	warn("? BrainrotBases folder NOT FOUND in Workspace!")
	return
end
print("? Found BrainrotBases folder")

-- Track assigned bases
local assignedBases = {} -- [playerName] = baseModel
local availableBases = {} -- Queue of unassigned bases

-- Initialize available bases list
for _, base in pairs(BASES_FOLDER:GetChildren()) do
	if base:IsA("Model") then
		local ownerValue = base:FindFirstChild("Owner")
		if ownerValue and ownerValue:IsA("StringValue") and ownerValue.Value == "" then
			table.insert(availableBases, base)
		end
	end
end

print("?? Found " .. #availableBases .. " available bases for assignment")

-- Function to assign a base to a player
local function assignBaseToPlayer(player)
	-- Check if player already has a base
	if assignedBases[player.Name] then
		print("? " .. player.Name .. " already has base: " .. assignedBases[player.Name].Name)
		return assignedBases[player.Name]
	end

	-- Find an available base
	if #availableBases == 0 then
		warn("?? No available bases to assign to " .. player.Name)
		return nil
	end

	-- Assign the first available base
	local base = table.remove(availableBases, 1)
	local ownerValue = base:FindFirstChild("Owner")

	if ownerValue and ownerValue:IsA("StringValue") then
		ownerValue.Value = player.Name
		assignedBases[player.Name] = base

		-- Set the spawn location
		local spawnLocation = base:FindFirstChild("SpawnLocation")
		if spawnLocation and spawnLocation:IsA("SpawnLocation") then
			-- Configure spawn location
			spawnLocation.Enabled = true
			spawnLocation.Duration = 0
			spawnLocation.Neutral = false
			spawnLocation.AllowTeamChangeOnTouch = false

			-- Set this as the player's respawn location
			player.RespawnLocation = spawnLocation

			print("? Assigned " .. base.Name .. " to " .. player.Name .. " with spawn point")

			-- Wait for character to load, then teleport
			if player.Character then
				local humanoidRootPart = player.Character:WaitForChild("HumanoidRootPart", 5)
				if humanoidRootPart then
					humanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0)
				end
			else
				-- If character hasn't loaded yet, wait for it
				player.CharacterAdded:Connect(function(character)
					local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
					if humanoidRootPart then
						humanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0)
					end
				end)
			end
		else
			warn("?? No SpawnLocation found in " .. base.Name)
		end

		return base
	end

	return nil
end

-- Function to unassign a base when player leaves
local function unassignBase(player)
	local base = assignedBases[player.Name]
	if base then
		local ownerValue = base:FindFirstChild("Owner")
		if ownerValue and ownerValue:IsA("StringValue") then
			ownerValue.Value = ""
		end

		-- Clear player's respawn location
		player.RespawnLocation = nil

		-- Return base to available pool
		table.insert(availableBases, base)
		assignedBases[player.Name] = nil

		print("?? Unassigned " .. base.Name .. " from " .. player.Name)
	end
end

-- Auto-assign bases when players join
Players.PlayerAdded:Connect(function(player)
	print("?? Player joined: " .. player.Name)
	assignBaseToPlayer(player)
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
	print("?? Player leaving: " .. player.Name)
	unassignBase(player)
end)

-- Assign bases to any players already in the game (for testing in Studio)
for _, player in pairs(Players:GetPlayers()) do
	assignBaseToPlayer(player)
end

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local placeBrainrotEvent = remoteEvents:FindFirstChild("PlaceBrainrotEvent")
if not placeBrainrotEvent then
	placeBrainrotEvent = Instance.new("RemoteEvent")
	placeBrainrotEvent.Name = "PlaceBrainrotEvent"
	placeBrainrotEvent.Parent = remoteEvents
end

local collectIncomeEvent = remoteEvents:FindFirstChild("CollectIncomeEvent")
if not collectIncomeEvent then
	collectIncomeEvent = Instance.new("RemoteEvent")
	collectIncomeEvent.Name = "CollectIncomeEvent"
	collectIncomeEvent.Parent = remoteEvents
end

-- ==========================================================
-- SHARED STATE
-- slotData[slot]       income tracking per occupied slot
-- incomeLabels[slot]   direct reference to the TextLabel on that slot's
--                        CollectTrigger billboard (created during the scan,
--                        before any brainrot is placed, so we never have to
--                        walk the instance tree again)
-- ==========================================================
local slotData      = {}
local incomeLabels  = {}   -- [slot Model] = TextLabel

-- ==========================================================
-- BILLBOARD HELPERS  (colour rules match the spawning system)
-- ==========================================================
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

-- Apply rainbow effect to all parts in a model
local function animateRainbowModel(model)
	task.spawn(function()
		local hue = 0
		local parts = {}

		-- Collect all parts
		for _, descendant in pairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
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
				0,
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
		while model and model.Parent do
			flip = not flip
			local col = flip and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
			for _, p in pairs(parts) do
				if p and p.Parent then p.Color = col end
			end
			task.wait(0.5)
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

-- Apply mutation visual effects to the brainrot model
local function applyMutationVisuals(brainrotModel, mutation)
	if not mutation then return end

	-- Helper: strip SurfaceAppearance so color changes actually apply
	local function stripAndColor(part, color, material, reflectance)
		if part:IsA("BasePart") then
			local sa = part:FindFirstChildOfClass("SurfaceAppearance")
			if sa then sa:Destroy() end
			if color then part.Color = color end
			if material then part.Material = material end
			if reflectance then part.Reflectance = reflectance end
		elseif part:IsA("SpecialMesh") then
			part.TextureId = ""
		end
	end

	-- Strip SurfaceAppearances first for all animated mutations
	if mutation == "Rainbow" or mutation == "Galaxy" or mutation == "Yin-Yang" or mutation == "Radioactive" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			local sa = d:FindFirstChildOfClass("SurfaceAppearance")
			if sa then sa:Destroy() end
			if d:IsA("SpecialMesh") then d.TextureId = "" end
		end
	end

	if mutation == "Rainbow" then
		animateRainbowModel(brainrotModel)

	elseif mutation == "Gold" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			stripAndColor(d, Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, nil)
			if d:IsA("SpecialMesh") then d.TextureId = "" end
		end

	elseif mutation == "Diamond" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			stripAndColor(d, Color3.fromRGB(185, 242, 255), Enum.Material.SmoothPlastic, 0.3)
			if d:IsA("SpecialMesh") then d.TextureId = "" end
		end

	elseif mutation == "Bloodrot" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			stripAndColor(d, Color3.fromRGB(100, 0, 0), Enum.Material.SmoothPlastic, nil)
		end

	elseif mutation == "Candy" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			stripAndColor(d, Color3.fromRGB(255, 105, 180), Enum.Material.SmoothPlastic, 0.1)
		end

	elseif mutation == "Lava" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			stripAndColor(d, Color3.fromRGB(255, 80, 0), Enum.Material.Neon, nil)
		end

	elseif mutation == "Galaxy" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			stripAndColor(d, Color3.fromRGB(138, 43, 226), Enum.Material.Neon, nil)
		end
		animateGalaxy(brainrotModel)

	elseif mutation == "Yin-Yang" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			stripAndColor(d, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, nil)
		end
		animateYinYang(brainrotModel)

	elseif mutation == "Radioactive" then
		for _, d in pairs(brainrotModel:GetDescendants()) do
			stripAndColor(d, Color3.fromRGB(0, 255, 50), Enum.Material.Neon, nil)
		end
		animateRadioactive(brainrotModel)
	end
end

local function getModelHeight(model)
	local _, size = model:GetBoundingBox()
	return size.Y
end

-- Nametag on the brainrot itself: Name / Rarity / Mutation (if any) / +$X/sec
-- Nametag on the brainrot itself: Name / Rarity / Mutation (if any) / +$X/sec
-- Modified to accept 'targetAdornee' (The Slot's DisplayPosition)
-- NEW: Separate prominent rarity display that's always visible
local function addRarityDisplay(brainrotModel, targetAdornee)
	local rarity = brainrotModel:GetAttribute("Rarity") or "Common"
	local modelHeight = getModelHeight(brainrotModel)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RarityDisplay"
	billboard.Adornee = targetAdornee
	billboard.Size = UDim2.new(6, 0, 1.5, 0)  -- Larger size
	billboard.StudsOffsetWorldSpace = Vector3.new(0, modelHeight + 4.5, 0)  -- Higher up
	billboard.AlwaysOnTop = true  -- Always visible
	billboard.MaxDistance = 500
	billboard.Parent = brainrotModel

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 1, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = "? " .. rarity .. " ?"
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.FredokaOne
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	rarityLabel.Parent = billboard

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = 40
	constraint.MinTextSize = 20
	constraint.Parent = rarityLabel

	-- Apply color
	local rarityColor = RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
	if rarityColor == "Rainbow" then
		animateRainbow(rarityLabel)
	elseif rarityColor == "Split" then
		rarityLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
	else
		rarityLabel.TextColor3 = rarityColor
	end
end

-- Modified name tag (now without prominent rarity)
local function addSlotNameTag(brainrotModel, incomeRate, mutation, targetAdornee)
	local rarity = brainrotModel:GetAttribute("Rarity") or "Common"
	local modelHeight = getModelHeight(brainrotModel)
	local hasMutation = mutation ~= nil

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Adornee = targetAdornee 
	billboard.Size = UDim2.new(4, 0, hasMutation and 1.75 or 1.25, 0)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, modelHeight + 2, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 400

	-- Name row
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, hasMutation and 0.33 or 0.5, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = brainrotModel.Name
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboard

	-- Mutation row (if exists)
	local mutationLabel
	if hasMutation then
		mutationLabel = Instance.new("TextLabel")
		mutationLabel.Size = UDim2.new(1, 0, 0.33, 0)
		mutationLabel.Position = UDim2.new(0, 0, 0.33, 0)
		mutationLabel.BackgroundTransparency = 1
		mutationLabel.Text = "? " .. mutation .. " ?"
		mutationLabel.TextSize = 14
		mutationLabel.Font = Enum.Font.SourceSansBold
		mutationLabel.TextStrokeTransparency = 0.5
		mutationLabel.Parent = billboard
	end

	-- Income row
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, 0, hasMutation and 0.33 or 0.5, 0)
	incomeLabel.Position = UDim2.new(0, 0, hasMutation and 0.66 or 0.5, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "+$" .. incomeRate .. "/sec"
	incomeLabel.TextSize = 14
	incomeLabel.Font = Enum.Font.SourceSansBold
	incomeLabel.TextStrokeTransparency = 0.5
	incomeLabel.Parent = billboard

	-- Apply colours
	local rarityColor = RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
	if rarityColor == "Rainbow" then
		animateRainbow(nameLabel)
		animateRainbow(incomeLabel)
	elseif rarityColor == "Split" then
		nameLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		incomeLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
	else
		nameLabel.TextColor3 = rarityColor
		incomeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	end

	if hasMutation and mutationLabel then
		local mutationColor = MUTATION_COLORS[mutation]
		if mutationColor == "Rainbow" then
			animateRainbow(mutationLabel)
		elseif mutationColor == "YinYang" then
			-- Alternate the label too
			task.spawn(function()
				local flip = false
				while mutationLabel and mutationLabel.Parent do
					flip = not flip
					mutationLabel.TextColor3 = flip and Color3.new(1,1,1) or Color3.new(0,0,0)
					task.wait(0.5)
				end
			end)
		elseif mutationColor then
			mutationLabel.TextColor3 = mutationColor
		end
	end

	billboard.Parent = brainrotModel 
end

-- "$0" billboard on the CollectTrigger.  Returns the TextLabel so we can
-- cache it and update cheaply every second.


-- ==========================================================
-- CORE LOGIC
-- ==========================================================
local function playerOwnsBase(player, slot)
	local base = slot.Parent
	if not base or not base:IsA("Model") then return false end
	local ownerValue = base:FindFirstChild("Owner")
	return ownerValue and ownerValue:IsA("StringValue") and ownerValue.Value == player.Name
end

-- Returns the tool only if it exists in Brainrot pack1
local function getEquippedBrainrot(player)
	if not player.Character then return nil end
	local tool = player.Character:FindFirstChildOfClass("Tool")
	if not tool or not BrainrotPackFolder then return nil end
	for _, item in pairs(BrainrotPackFolder:GetChildren()) do
		if item.Name == tool.Name then return tool end
	end
	return nil
end

-- PLACE    moves the tool into the slot (no clone, no destroy)
-- Helper to get Rebirths (Place this above the main function if you haven't already)
local function getRebirthMultiplier(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			-- Formula: 1x base + 0.5x per rebirth (e.g., 2 Rebirths = 2x income)
			return 1 + (rebirths.Value * 0.5) 
		end
	end
	return 1
end
-- Function to show ownership warning GUI with animation
local hideTask = nil 
local currentTween = nil 

local function showOwnershipWarning(player)
	local playerGui = player:WaitForChild("PlayerGui", 5)
	if not playerGui then return end

	local sg = playerGui:FindFirstChild("OwnershipGUI")
	if not sg then return end

	local f = sg:FindFirstChild("MainFrame")
	if not f then return end

	-- 1. CANCEL OLD TIMERS
	-- If the GUI is already waiting to go up, stop the timer so it stays down.
	if hideTask then
		task.cancel(hideTask)
		hideTask = nil
	end

	-- 2. STOP CURRENT MOTION
	if currentTween then
		currentTween:Cancel()
	end

	-- 3. RESET START POSITION (Only if hidden)
	if not sg.Enabled then
		sg.Enabled = true
		f.Position = UDim2.new(0.5, 0, -0.2, 0)
	end

	-- 4. DROP ANIMATION (TIGHTER ELASTIC)
	-- 0.8 seconds is the "sweet spot" for Elastic. 
	-- It snaps into place like a real spring.
	local dropInfo = TweenInfo.new(
		0.8, 
		Enum.EasingStyle.Elastic, 
		Enum.EasingDirection.Out
	)

	currentTween = TweenService:Create(f, dropInfo, {
		Position = UDim2.new(0.5, 0, 0.15, 0)
	})
	currentTween:Play()

	-- 5. WAIT & HIDE
	hideTask = task.spawn(function()
		-- CHANGED: Reduced wait time to 1.2 seconds (Stay on ground for less)
		task.wait(1.2)

		local upInfo = TweenInfo.new(
			0.4, -- Fast exit
			Enum.EasingStyle.Back, -- "Back" creates a nice anticipation effect
			Enum.EasingDirection.In
		)

		currentTween = TweenService:Create(f, upInfo, {
			Position = UDim2.new(0.5, 0, -0.2, 0)
		})
		currentTween:Play()
		currentTween.Completed:Wait()

		-- Fully hide
		sg.Enabled = false
		hideTask = nil
		currentTween = nil
	end)
end
-- THE MAIN FUNCTION
local function placeBrainrotOnSlot(player, slot)
	-- 1. Check Ownership
	if not playerOwnsBase(player, slot) then
		showOwnershipWarning(player)
		return false, "You don't own this base!"

	end

	local displayPart = slot:FindFirstChild("DisplayPosition")
	if not displayPart then
		return false, "Slot missing DisplayPosition!"
	end

	-- 2. DECIDE: Pickup or Place?
	local currentSlotData = slotData[slot]

	if currentSlotData then
		-- ==========================================
		--               PICKUP LOGIC
		-- ==========================================

		-- A. Auto-Collect Income (Don't lose money on pickup!)
		local timeElapsed = tick() - currentSlotData.lastUpdate
		local earned = math.ceil(timeElapsed * currentSlotData.incomeRate)
		local totalToGive = currentSlotData.accumulatedIncome + earned

		if totalToGive > 0 then
			local leaderstats = player:FindFirstChild("leaderstats")
			local money = leaderstats and leaderstats.Parent:FindFirstChild("MoneyRaw")
			if money then
				money.Value += totalToGive
				-- Update the visual label to $0
				if currentSlotData.incomeLabel then
					currentSlotData.incomeLabel.Text = "$0"
					currentSlotData.incomeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				end
				-- Optional: Fire client event for popup
				collectIncomeEvent:FireClient(player, true, "Collected on pickup!", totalToGive)
			end
		end

		-- B. Find the tool
		local brainrot = displayPart:FindFirstChildWhichIsA("Tool")
		if not brainrot then
			slotData[slot] = nil
			return false, "Glitch: Slot empty but data existed. Resetting."
		end

		-- C. Reset Tool Physics
		brainrot.Enabled = true
		for _, part in pairs(brainrot:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false 
			end
		end

		-- D. Give to Player
		brainrot.Parent = player.Character 

		-- E. Clean up Data
		local tag = brainrot:FindFirstChild("NameTag")
		if tag then tag:Destroy() end

		slotData[slot] = nil 

		slot:SetAttribute("HasBrainrot", nil)
		slot:SetAttribute("BrainrotName", nil)
		slot:SetAttribute("IncomeRate", nil)
		slot:SetAttribute("Mutation", nil)

		return true, "Picked up " .. brainrot.Name .. "!"

	else
		-- ==========================================
		--               PLACE LOGIC
		-- ==========================================

		local brainrot = getEquippedBrainrot(player)
		if not brainrot then
			return false, "Equip a valid Brainrot first!"
		end

		-- A. Calculate Base Rate
		local baseIncome = BRAINROT_INCOME[brainrot.Name]
		if not baseIncome then
			warn("?? '" .. brainrot.Name .. "' not in BRAINROT_INCOME. Defaulting to 1.")
			baseIncome = 1
		end

		-- B. Apply Rebirth Multiplier (for display purposes)
		local rebirthMult = getRebirthMultiplier(player)

		-- C. Read Mutation (if it exists from spawning system) for display
		local mutation = brainrot:GetAttribute("Mutation")
		local mutationMult = brainrot:GetAttribute("MutationMult") or 1
		if mutation then
			mutationMult = MUTATION_MULTIPLIERS[mutation] or 1
			print("? READING MUTATION: " .. brainrot.Name .. " has " .. mutation .. "! (" .. mutationMult .. "x multiplier)")
		end

		-- D. Calculate display income rate (mutations will be applied during collection)
		local finalIncomeRate = math.ceil(baseIncome * rebirthMult * mutationMult)
		local brainrotName = brainrot.Name

		-- E. Move Tool
		brainrot.Parent = displayPart
		brainrot.Enabled = false

		-- F. Lock Physics
		for _, part in pairs(brainrot:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				if part.Name == "Handle" and part:FindFirstChild("TouchInterest") then
					part.TouchInterest:Destroy()
				end
			end
		end

		-- G. Position
		brainrot:PivotTo(displayPart.CFrame * CFrame.Angles(0, math.rad(90), 0))

		-- H. Add UI (with mutation info)
		-- H. Add UI (with mutation info)
addRarityDisplay(brainrot, displayPart)  -- ADD THIS NEW LINE
addSlotNameTag(brainrot, finalIncomeRate, mutation, displayPart)

		-- I. Apply mutation visual effects
		if mutation then
			applyMutationVisuals(brainrot, mutation)
		end

		-- I. Save Data (mutation will be read from tool during collection)
		slotData[slot] = {
			brainrotName      = brainrotName,
			baseIncome        = baseIncome,  -- Store base for recalculation
			incomeRate        = finalIncomeRate, -- Current calculated rate (for display)
			accumulatedIncome = 0,
			lastUpdate        = tick(),
			incomeLabel       = incomeLabels[slot],
			tool              = brainrot,    -- Store reference to the tool itself
		}

		slot:SetAttribute("HasBrainrot",  true)
		slot:SetAttribute("BrainrotName", brainrotName)
		slot:SetAttribute("IncomeRate",   finalIncomeRate)
		if mutation then
			slot:SetAttribute("Mutation", mutation)
		end

		local mutationText = mutation and (" [" .. mutation .. " " .. mutationMult .. "x]") or ""
		print("? " .. player.Name .. " placed " .. brainrotName .. mutationText .. " (Rebirth: " .. rebirthMult .. "x, Final: $" .. finalIncomeRate .. "/sec)")
		return true, "Placed " .. brainrotName .. "! (+" .. finalIncomeRate .. "/sec)" .. (mutation and " [" .. mutation .. "!]" or "")
	end
end

-- COLLECT
local function collectIncome(player, slot)
	if not playerOwnsBase(player, slot) then
		showOwnershipWarning(player)
		return false, "You don't own this base!", 0

	end

	local data = slotData[slot]
	if not data then
		return false, "No brainrot in this slot!", 0
	end

	-- Get current multiplier dynamically
	local currentRebirthMult = getRebirthMultiplier(player)

	-- Get base income
	local baseIncome = data.baseIncome or BRAINROT_INCOME[data.brainrotName] or 1

	-- READ MUTATION FROM TOOL DYNAMICALLY
	local mutationMult = 1
	if data.tool and data.tool:IsDescendantOf(game) then
		local mutation = data.tool:GetAttribute("Mutation")
		if mutation then
			mutationMult = MUTATION_MULTIPLIERS[mutation] or 1
		end
	end

	-- Calculate the real rate right now (Base * Rebirth * Mutation)
	local currentRealRate = baseIncome * currentRebirthMult * mutationMult

	-- Accumulate since last tick using the REAL rate
	local now = tick()
	data.accumulatedIncome = data.accumulatedIncome + (now - data.lastUpdate) * currentRealRate
	data.lastUpdate = now

	local totalIncome = math.ceil(data.accumulatedIncome)
	if totalIncome <= 0 then
		return false, "No income to collect yet!", 0
	end

	-- Pay out
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false, "Leaderstats not found!", 0 end
	local money = leaderstats.Parent:FindFirstChild("MoneyRaw") or leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Coins")
	if not money then return false, "Money stat not found!", 0 end

	money.Value = money.Value + totalIncome
	data.accumulatedIncome = data.accumulatedIncome - totalIncome

	-- Immediately refresh the billboard
	-- Immediately refresh the billboard
	-- Immediately refresh the billboard
	if data.incomeLabel then
		local amount = math.ceil(data.accumulatedIncome)
		if amount > 0 then
			data.incomeLabel.Parent.Visible = true
			data.incomeLabel.Text = "$" .. amount
		else
			data.incomeLabel.Parent.Visible = false
		end
	end

	print("?? " .. player.Name .. " collected $" .. totalIncome .. " from " .. slot.Name)
	return true, "Collected $" .. totalIncome .. "!", totalIncome
end

-- ==========================================================
-- REMOTE EVENTS
-- ==========================================================
placeBrainrotEvent.OnServerEvent:Connect(function(player, slot)
	if typeof(slot) ~= "Instance" or not slot:IsDescendantOf(BASES_FOLDER) then return end
	local ok, msg = placeBrainrotOnSlot(player, slot)
	placeBrainrotEvent:FireClient(player, ok, msg)
end)

collectIncomeEvent.OnServerEvent:Connect(function(player, slot)
	if slot and typeof(slot) == "Instance" then
		local ok, msg, amount = collectIncome(player, slot)
		collectIncomeEvent:FireClient(player, ok, msg, amount)
	end
end)

-- ==========================================================
-- SCAN    wire up every CollectTrigger & ProximityPrompt once at startup
-- ==========================================================
print("?? Scanning BrainrotBases...")
local basesFound, slotsFound = 0, 0

for _, base in pairs(BASES_FOLDER:GetChildren()) do
	if not base:IsA("Model") then continue end
	basesFound += 1

	local ownerValue = base:FindFirstChild("Owner")
	print("?? Base:", base.Name, "| Owner:", ownerValue and ownerValue.Value or "?? NONE")

	for _, child in pairs(base:GetChildren()) do
		if not (child:IsA("Model") and child.Name:match("Slot")) then continue end
		slotsFound += 1
		local slot = child
		print("   ?? Slot:", slot.Name)

		-- 1. CollectTrigger    create billboard + touch handler
		local collectTrigger = slot:FindFirstChild("CollectTrigger")
		if collectTrigger then

			-- NEW LOGIC: Find existing GUI instead of creating one
			-- NEW LOGIC: Find existing GUI instead of creating one
			local bb = collectTrigger:FindFirstChild("IncomeBillboard")
			local frame = bb and bb:FindFirstChild("Frame")
			local label = frame and frame:FindFirstChild("IncomeText")

			if label then
				incomeLabels[slot] = label
				label.Text = "$0" -- Reset on load
				frame.Visible = false -- Hide it initially since there's no income yet
			end

			collectTrigger.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then return end
				local lastCollect = player:GetAttribute("LastCollectTime") or 0
				if tick() - lastCollect <= 0.5 then return end
				player:SetAttribute("LastCollectTime", tick())

				local ok, msg, amount = collectIncome(player, slot)
				if ok then collectIncomeEvent:FireClient(player, ok, msg, amount) end
			end)
			print("      ? CollectTrigger connected")
		else
			print("      ? No CollectTrigger")
		end
		-- 2. ProximityPrompt    check slot directly, then one level deeper
		local placePrompt = slot:FindFirstChild("PlacePrompt")
		if not placePrompt then
			for _, part in pairs(slot:GetChildren()) do
				local found = part:FindFirstChild("PlacePrompt")
				if found then placePrompt = found; break end
			end
		end

		if placePrompt and placePrompt:IsA("ProximityPrompt") then
			placePrompt.Triggered:Connect(function(player)
				local ok, msg = placeBrainrotOnSlot(player, slot)
				placeBrainrotEvent:FireClient(player, ok, msg)
			end)
			print("      ? PlacePrompt connected")
		else
			print("      ?? No PlacePrompt found")
		end
	end
end

print("?? Scan done ", basesFound, "bases,", slotsFound, "slots")

-- ==========================================================
-- UPDATE LOOP    accumulate income & refresh billboards every second
-- ==========================================================
task.spawn(function()
    while true do
        task.wait(1)

        -- 1. Initialize totals ONLY for players who actually own a base
        local playerTotals = {} 
        for playerName, base in pairs(assignedBases) do
            playerTotals[playerName] = 0
        end

        -- 2. Calculate income from active slots
        for slot, data in pairs(slotData) do
            -- Find the owner of this slot
            local base = slot.Parent
            local ownerValue = base and base:FindFirstChild("Owner")
            local ownerName = ownerValue and ownerValue.Value
            local player = Players:FindFirstChild(ownerName)

            -- If the player is still in the game (and owns this slot)
            if player then
                local currentRealRate = 1 

                -- Get multipliers
                local rebirthMult = getRebirthMultiplier(player)

                -- Base income
                local baseIncome = data.baseIncome or BRAINROT_INCOME[data.brainrotName] or 1

                -- Mutation maultiplier
                local mutationMult = 1
                if data.tool and data.tool:IsDescendantOf(game) then
                    local mutation = data.tool:GetAttribute("Mutation")
                    if mutation then
                        mutationMult = MUTATION_MULTIPLIERS[mutation] or 1
                    end
                end

                -- Final Calc
                currentRealRate = baseIncome * rebirthMult * mutationMult

                -- ADD TO PLAYER TOTAL
                if playerTotals[player.Name] ~= nil then
                    playerTotals[player.Name] = playerTotals[player.Name] + currentRealRate
                end

                -- Accumulate income for the slot (Backend logic)
                local now = tick()
                data.accumulatedIncome = data.accumulatedIncome + (now - data.lastUpdate) * currentRealRate
                data.lastUpdate = now

                -- Update the small text on the slot itself
				-- Update the small text on the slot itself
				local label = data.incomeLabel
				if label then
					local amount = math.ceil(data.accumulatedIncome)

					if amount > 0 then
						-- Show the background frame and text
						label.Parent.Visible = true 
						label.Text = "$" .. amount

						if amount >= 100 then
							label.TextColor3 = Color3.fromRGB(255, 100, 255)   -- purple
						elseif amount >= 50 then
							label.TextColor3 = Color3.fromRGB(255, 215, 0)     -- gold
						else
							label.TextColor3 = Color3.fromRGB(100, 255, 100)   -- green
						end
					else
						-- Hide everything if 0
						label.Parent.Visible = false 
					end
				
                    -- >>> CHANGED LOGIC END <<<
                end
            end
        end

        -- 3. PRINT & UPDATE GUI ONLY FOR BASE OWNERS
        for playerName, totalMPS in pairs(playerTotals) do
            -- (Keep your existing MPS display logic here exactly as it was)
            local player = Players:FindFirstChild(playerName)
            if player and player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local incomeGui = rootPart:FindFirstChild("MPSDisplay")
                    local textLabel
                    if not incomeGui then
                        incomeGui = Instance.new("BillboardGui")
                        incomeGui.Name = "MPSDisplay"
                        incomeGui.Size = UDim2.new(6, 0, 1.5, 0) 
                        incomeGui.StudsOffset = Vector3.new(0, 3.5, 0) 
                        incomeGui.AlwaysOnTop = true 
                        
                        textLabel = Instance.new("TextLabel")
                        textLabel.Parent = incomeGui
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.BackgroundTransparency = 1
                        textLabel.TextScaled = true 
                        textLabel.Font = Enum.Font.FredokaOne
                        textLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
                        textLabel.TextStrokeTransparency = 0 
                        
                        incomeGui.Parent = rootPart
                    else
                        textLabel = incomeGui:FindFirstChild("TextLabel")
                    end

                    if textLabel then
                        textLabel.Text = "+$" .. totalMPS .. "/s"
                    end
                end
            end
        end
    end
end)

print("? BrainrotSlotSystem fully loaded with mutation support!")


-- ==========================================================
-- UPDATE LOOP  accumulate income & refresh billboards every second
-- ==========================================================
task.spawn(function()
	while true do
		task.wait(1)

		-- 1. Initialize totals ONLY for players who actually own a base
		local playerTotals = {} 
		for playerName, base in pairs(assignedBases) do
			playerTotals[playerName] = 0
		end

		-- 2. Calculate income from active slots
		for slot, data in pairs(slotData) do
			-- Find the owner of this slot
			local base = slot.Parent
			local ownerValue = base and base:FindFirstChild("Owner")
			local ownerName = ownerValue and ownerValue.Value
			local player = Players:FindFirstChild(ownerName)

			-- If the player is still in the game (and owns this slot)
			if player then
				local currentRealRate = 1 

				-- Get multipliers
				local rebirthMult = getRebirthMultiplier(player)

				-- Base income
				local baseIncome = data.baseIncome or BRAINROT_INCOME[data.brainrotName] or 1

				-- Mutation multiplier
				local mutationMult = 1
				if data.tool and data.tool:IsDescendantOf(game) then
					local mutation = data.tool:GetAttribute("Mutation")
					if mutation then
						mutationMult = MUTATION_MULTIPLIERS[mutation] or 1
					end
				end

				-- Final Calc
				currentRealRate = baseIncome * rebirthMult * mutationMult

				-- ADD TO PLAYER TOTAL
				-- We only add if they are in our 'assignedBases' list (sanity check)
				if playerTotals[player.Name] ~= nil then
					playerTotals[player.Name] = playerTotals[player.Name] + currentRealRate
				end

				-- Accumulate income for the slot (Backend logic)
				local now = tick()
				data.accumulatedIncome = data.accumulatedIncome + (now - data.lastUpdate) * currentRealRate
				data.lastUpdate = now

				-- Update the small text on the slot itself
				local label = data.incomeLabel
				if label then
					local amount = math.ceil(data.accumulatedIncome)
					label.Text = "$" .. amount

					if amount >= 100 then
						label.TextColor3 = Color3.fromRGB(255, 100, 255)   -- purple
					elseif amount >= 50 then
						label.TextColor3 = Color3.fromRGB(255, 215, 0)     -- gold
					else
						label.TextColor3 = Color3.fromRGB(100, 255, 100)   -- green
					end
				end
			end
		end

		-- 3. PRINT & UPDATE GUI ONLY FOR BASE OWNERS
		for playerName, totalMPS in pairs(playerTotals) do
			

			local player = Players:FindFirstChild(playerName)
			if player and player.Character then
				local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

				if rootPart then
					local incomeGui = rootPart:FindFirstChild("MPSDisplay")
					local textLabel

					if not incomeGui then
						-- CREATE IT ONLY ONCE
						incomeGui = Instance.new("BillboardGui")
						incomeGui.Name = "MPSDisplay"
						incomeGui.Size = UDim2.new(6, 0, 1.5, 0) 
						incomeGui.StudsOffset = Vector3.new(0, 3.5, 0) 
						incomeGui.AlwaysOnTop = true 

						textLabel = Instance.new("TextLabel")
						textLabel.Parent = incomeGui
						textLabel.Size = UDim2.new(1, 0, 1, 0)
						textLabel.BackgroundTransparency = 1
						textLabel.TextScaled = true 
						textLabel.Font = Enum.Font.FredokaOne
						textLabel.TextColor3 = Color3.fromRGB(85, 255, 127) -- Money Green
						textLabel.TextStrokeTransparency = 0 -- Black outline

						incomeGui.Parent = rootPart
					else
						textLabel = incomeGui:FindFirstChild("TextLabel")
					end

					if textLabel then
						textLabel.Text = "+$" .. totalMPS .. "/s"
					end
				end
			end
		end
	end
end)