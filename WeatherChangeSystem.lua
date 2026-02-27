local Remotes             = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local weatherChangedEvent = Remotes:WaitForChild("WeatherChanged")
local getWeatherFunc      = Remotes:WaitForChild("GetCurrentWeather")
local WeatherSystem       = require(game.ReplicatedStorage:WaitForChild("WeatherSystem"))
local rainEvent           = Remotes:WaitForChild("StartRain") -- Fixed capitalization to match standard naming
local RunService          = game:GetService("RunService")

-- Mutation colors (must match Spawning System)
local MUTATION_COLORS = {
	["Gold"]        = Color3.fromRGB(255, 215, 0),
	["Diamond"]     = Color3.fromRGB(185, 242, 255),
	["Rainbow"]     = "Rainbow",
	["Bloodrot"]    = Color3.fromRGB(100, 0, 0),
	["Candy"]       = Color3.fromRGB(255, 105, 180),
	["Lava"]        = Color3.fromRGB(255, 80, 0),
	["Galaxy"]      = Color3.fromRGB(138, 43, 226),
	["Yin-Yang"]    = "YinYang",
	["Radioactive"] = Color3.fromRGB(0, 255, 50),
	["Wet"] = Color3.fromRGB(84, 130, 255)
}

-- Mutation multipliers (must match Spawning System)
local MUTATION_MULTIPLIERS = {
	["Gold"]        = 1.25,
	["Diamond"]     = 1.50,
	["Rainbow"]     = 10.0,
	["Bloodrot"]    = 2.0,
	["Candy"]       = 4.0,
	["Lava"]        = 6.0,
	["Galaxy"]      = 7.0,
	["Yin-Yang"]    = 7.5,
	["Radioactive"] = 8.5,
	["Wet"] = 1.5
}

-- Ensure WeatherSystem is fully loaded before accessing its properties
local EVENT_DURATION = WeatherSystem.EVENT_DURATION or 15
local CLEAR_DURATION = WeatherSystem.CLEAR_DURATION or 15

local function isDeveloper(player)
	if RunService:IsStudio() then return true end
	return player.UserId == game.CreatorId or player.UserId == 10378926133
end

local function getNextEvent()
	local events = WeatherSystem.WEATHER_EVENTS
	local idx = math.random(1, #events)
	local attempts = 0
	while idx == WeatherSystem._lastEventIndex and attempts < 10 do
		idx = math.random(1, #events)
		attempts += 1
	end
	WeatherSystem._lastEventIndex = idx
	return events[idx]
end

-- ============================================================
--  HELPER: Clean up mutations when weather changes
-- ============================================================
-- ============================================================
--  HELPER: Clean up mutations when weather changes
-- ============================================================


-- ============================================================
--  HELPER: set weather and broadcast
-- ============================================================
-- ============================================================
--  MUTATION STACKING HELPERS
-- ============================================================
local PERM_MUTATIONS = { ["Gold"]=true, ["Diamond"]=true, ["Rainbow"]=true }
local LIMITED_MUTATIONS = { ["Bloodrot"]=true, ["Candy"]=true, ["Lava"]=true, ["Galaxy"]=true, ["Yin-Yang"]=true, ["Radioactive"]=true, ["Wet"]=true }

local function getParsedMutations(mutationString)
	local perm, limited
	if not mutationString then return nil, nil end
	for p in pairs(PERM_MUTATIONS) do
		if string.find(mutationString, p) then perm = p end
	end
	for l in pairs(LIMITED_MUTATIONS) do
		if string.find(mutationString, l) then limited = l end
	end
	return perm, limited
end

local function calculateCombinedMultiplier(perm, limited)
	local bonus = 0
	if perm then bonus += (MUTATION_MULTIPLIERS[perm] or 0) end
	if limited then bonus += (MUTATION_MULTIPLIERS[limited] or 0) end
	return 1 + bonus
end

local function updateBrainrotMutationAndVisuals(luckyRot, perm, limited, visualData)
	-- Combine the names (e.g. "Gold, Radioactive")
	local newMutString
	if perm and limited then newMutString = perm .. ", " .. limited
	elseif perm then newMutString = perm
	elseif limited then newMutString = limited end

	luckyRot:SetAttribute("Mutation", newMutString)
	luckyRot:SetAttribute("MutationMult", calculateCombinedMultiplier(perm, limited))

	-- 1. UPDATE OVERHEAD LABEL
	local statsGUI = luckyRot:FindFirstChild("StatsGUI")
	if statsGUI then
		local lbl = statsGUI:FindFirstChild("MutationLabel")
		if not lbl then
			lbl = Instance.new("TextLabel")
			lbl.Name = "MutationLabel"
			lbl.Size = UDim2.new(1, 0, 0.2, 0)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.SourceSansBold
			lbl.TextScaled = true
			lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
			lbl.TextStrokeTransparency = 0
			lbl.LayoutOrder = 2

			local constraint = Instance.new("UITextSizeConstraint")
			constraint.MaxTextSize = 35
			constraint.MinTextSize = 2
			constraint.Parent = lbl

			lbl.Parent = statsGUI
		end

		lbl.Text = "⭐ " .. newMutString .. " ⭐"

		-- Color priority: Limited overwrites Perm on the label
		local mc = nil
		if limited and MUTATION_COLORS[limited] then mc = MUTATION_COLORS[limited]
		elseif perm and MUTATION_COLORS[perm] then mc = MUTATION_COLORS[perm] end

		if mc and typeof(mc) == "Color3" then lbl.TextColor3 = mc
		else lbl.TextColor3 = Color3.new(1,1,1) end
	end

	-- 2. APPLY VISUALS (Only applies Weather visual overrides)
	if visualData then
		for _, d in pairs(luckyRot:GetDescendants()) do
			if d:IsA("BasePart") or d:IsA("MeshPart") then
				local sa = d:FindFirstChildOfClass("SurfaceAppearance")
				if sa then sa:Destroy() end
				if visualData.material then d.Material = visualData.material end
				if visualData.reflectance then d.Reflectance = visualData.reflectance end
				if visualData.color and visualData.animated == false then d.Color = visualData.color end
			elseif d:IsA("SpecialMesh") then
				d.TextureId = ""
			end
		end

		-- Check if the specific limited mutation is still active before continuing the loop
		if visualData.animated == "galaxy" then
			task.spawn(function()
				local parts = {}
				for _, d in pairs(luckyRot:GetDescendants()) do
					if d:IsA("BasePart") then table.insert(parts, d) end
				end
				local t = 0
				while luckyRot and luckyRot.Parent and string.find(luckyRot:GetAttribute("Mutation") or "", limited) do
					t += 0.02
					local brightness = 0.5 + 0.5 * math.sin(t)
					local col = Color3.fromRGB(math.floor(75 + 63 * brightness), 0, math.floor(130 + 100 * brightness))
					for _, p in pairs(parts) do if p and p.Parent then p.Color = col end end
					task.wait(0.05)
				end
			end)
		elseif visualData.animated == "yinyang" then
			task.spawn(function()
				local parts = {}
				for _, d in pairs(luckyRot:GetDescendants()) do
					if d:IsA("BasePart") then table.insert(parts, d) end
				end
				local flip = false
				while luckyRot and luckyRot.Parent and string.find(luckyRot:GetAttribute("Mutation") or "", limited) do
					flip = not flip
					local col = flip and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
					for _, p in pairs(parts) do if p and p.Parent then p.Color = col end end
					task.wait(0.5)
				end
			end)
		elseif visualData.animated == "radioactive" then
			task.spawn(function()
				local parts = {}
				for _, d in pairs(luckyRot:GetDescendants()) do
					if d:IsA("BasePart") then table.insert(parts, d) end
				end
				local t = 0
				while luckyRot and luckyRot.Parent and string.find(luckyRot:GetAttribute("Mutation") or "", limited) do
					t += 0.08
					local brightness = 0.5 + 0.5 * math.sin(t)
					local g = math.floor(150 + 105 * brightness)
					local col = Color3.fromRGB(0, g, 0)
					for _, p in pairs(parts) do if p and p.Parent then p.Color = col end end
					task.wait(0.05)
				end
			end)
		end
	end
end

-- ============================================================
--  MAIN WEATHER CHANGE FUNCTION
-- ============================================================
local function setWeather(weatherName, duration)
	local data = WeatherSystem.WEATHER_TYPES[weatherName]
	local newLimitedMutation = data and data.mutation
	local visualData = nil

	-- Safely get visual data (Checking both possible locations)
	if newLimitedMutation then
		if WeatherSystem.LIMITED_VISUALS and WeatherSystem.LIMITED_VISUALS[newLimitedMutation] then
			visualData = WeatherSystem.LIMITED_VISUALS[newLimitedMutation]
		elseif data.visualData then
			visualData = data.visualData
		end
	end

	WeatherSystem._currentWeather = weatherName
	WeatherSystem._weatherEndTime = tick() + duration

	print(string.format("🌦️ Weather changed → %s (lasts %ds)", data.displayName, duration))
	weatherChangedEvent:FireAllClients(weatherName, data.displayName, data.color, data.description, duration)

	if weatherName == "Rain" then
		rainEvent:FireAllClients(false)
	else
		rainEvent:FireAllClients(true)
	end

	-- ==========================================
	-- 1. SWAP EXISTING MUTATIONS ON WEATHER CHANGE
	-- ==========================================
	if newLimitedMutation then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj:GetAttribute("Rarity") then
				local currentMut = obj:GetAttribute("Mutation")
				local perm, limited = getParsedMutations(currentMut)

				-- If it has an OLD limited mutation, REPLACE it with the NEW one immediately
				if limited and limited ~= newLimitedMutation then
					print("🔄 Swapped " .. limited .. " to " .. newLimitedMutation .. " on " .. obj.Name)
					updateBrainrotMutationAndVisuals(obj, perm, newLimitedMutation, visualData)
				end
			end
		end
	end

	-- ==========================================
	-- 2. RANDOM MUTATION LOOP
	-- ==========================================
	if weatherName ~= "Clear" and newLimitedMutation then
		task.spawn(function()
			local endTime = tick() + duration

			while tick() < endTime do
				task.wait(math.random(15, 30) / 10) 

				if tick() >= endTime or WeatherSystem._currentWeather ~= weatherName then 
					break 
				end

				local availableBrainrots = {}
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("Model") and obj:GetAttribute("Rarity") then
						local currentMut = obj:GetAttribute("Mutation")
						local perm, limited = getParsedMutations(currentMut)

						-- Only mutate it if it DOES NOT already have a limited weather mutation
						if not limited then
							table.insert(availableBrainrots, obj)
						end
					end
				end

				if #availableBrainrots > 0 then
					local luckyRot = availableBrainrots[math.random(1, #availableBrainrots)]
					local currentMut = luckyRot:GetAttribute("Mutation")
					local perm, _ = getParsedMutations(currentMut)

					-- Combine the new limited mutation with the existing perm mutation (if any)
					updateBrainrotMutationAndVisuals(luckyRot, perm, newLimitedMutation, visualData)

					if announceRemote then
						announceRemote:FireAllClients(luckyRot.Name, newLimitedMutation, data.color)
					end
				end
			end
		end)
	end
end
local forceWeatherEvent = Remotes:WaitForChild("ForceWeather")
forceWeatherEvent.OnServerEvent:Connect(function(player, weatherName)
	if not isDeveloper(player) then return end
	if WeatherSystem.WEATHER_TYPES[weatherName] then
		setWeather(weatherName, EVENT_DURATION)
	end
end)

-- ============================================================
--  WEATHER CYCLE LOOP
-- ============================================================



task.spawn(function()
	print("🌤️ Weather system started!")

	setWeather("Clear", CLEAR_DURATION)
	task.wait(CLEAR_DURATION)  -- was hardcoded to 30 — now uses your module value

	while true do
		local nextEvent = getNextEvent()
		setWeather(nextEvent, EVENT_DURATION)
		task.wait(EVENT_DURATION)

		setWeather("Clear", CLEAR_DURATION)
		task.wait(CLEAR_DURATION)
	end
end)



print("✅ WeatherController loaded.")
