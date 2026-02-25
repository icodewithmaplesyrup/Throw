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
--  HELPER: set weather and broadcast
-- ============================================================
local function setWeather(weatherName, duration)
	WeatherSystem._currentWeather = weatherName
	WeatherSystem._weatherEndTime = os.time() + duration

	local data = WeatherSystem.WEATHER_TYPES[weatherName]
	print(string.format("??? Weather changed ? %s (lasts %ds)", data.displayName, duration))

	-- Fire to all connected clients (General UI update)
	weatherChangedEvent:FireAllClients(
		weatherName,
		data.displayName,
		data.color,
		data.description,
		duration
	)

	-- ==========================================
	-- [RESTORED] Trigger the physical rain falling!
	-- ==========================================
	if weatherName == "Rain" then
		-- We now use the rainEvent defined at the very top of the script!
		rainEvent:FireAllClients(false)
	else
		rainEvent:FireAllClients(true)
	end

	-- [NEW] Random Mutation Loop over time
	if weatherName ~= "Clear" and data.mutation then
		task.spawn(function()
			local endTime = os.time() + duration
			local visualData = WeatherSystem.LIMITED_VISUALS[data.mutation]
			local announceRemote = Remotes:FindFirstChild("MutationAnnounced")

			-- Keep looping as long as the weather event is active
			while os.time() < endTime do
				-- Wait a random amount of time (e.g., every 1.5 to 3 seconds)
				task.wait(math.random(15, 30) / 10) 

				if os.time() >= endTime then break end

				-- Find all brainrots currently in the workspace
				local availableBrainrots = {}
				for _, obj in ipairs(workspace:GetDescendants()) do
					-- Must be a model, must have a Rarity, and must NOT already have a mutation
					if obj:IsA("Model") and obj:GetAttribute("Rarity") ~= nil and not obj:GetAttribute("Mutation") then
						table.insert(availableBrainrots, obj)
					end
				end

				if #availableBrainrots > 0 then
					-- Pick a random lucky (or unlucky) brainrot!
					local luckyRot = availableBrainrots[math.random(1, #availableBrainrots)]

					-- 1. Assign the mutation attribute so it gets the multiplier
					luckyRot:SetAttribute("Mutation", data.mutation)
					luckyRot:SetAttribute("MutationMult", MUTATION_MULTIPLIERS[data.mutation] or 1)

					-- 2. APPLY VISUALS dynamically
					if visualData then
						-- Strip SurfaceAppearances first
						for _, d in pairs(luckyRot:GetDescendants()) do
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
					end

					-- Apply animation if needed
					if visualData.animated == "galaxy" then
						-- Galaxy animation
						task.spawn(function()
							local parts = {}
							for _, d in pairs(luckyRot:GetDescendants()) do
								if d:IsA("BasePart") then table.insert(parts, d) end
							end
							local t = 0
							while luckyRot and luckyRot.Parent do
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
					elseif visualData.animated == "yinyang" then
						-- Yin-Yang animation
						task.spawn(function()
							local parts = {}
							for _, d in pairs(luckyRot:GetDescendants()) do
								if d:IsA("BasePart") then table.insert(parts, d) end
							end
							local flip = false
							while luckyRot and luckyRot.Parent do
								flip = not flip
								local col = flip and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
								for _, p in pairs(parts) do
									if p and p.Parent then p.Color = col end
								end
								task.wait(0.5)
							end
						end)
					elseif visualData.animated == "radioactive" then
						-- Radioactive animation
						task.spawn(function()
							local parts = {}
							for _, d in pairs(luckyRot:GetDescendants()) do
								if d:IsA("BasePart") then table.insert(parts, d) end
							end
							local t = 0
							while luckyRot and luckyRot.Parent do
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

					-- ==========================================
					-- [NEW] 2.5 UPDATE THE OVERHEAD BILLBOARD DYNAMICALLY
					-- ==========================================
					local statsGUI = luckyRot:FindFirstChild("StatsGUI")
					if statsGUI and not statsGUI:FindFirstChild("MutationLabel") then
						local mutationLabel = Instance.new("TextLabel")
						mutationLabel.Name = "MutationLabel"
						mutationLabel.Size = UDim2.new(1, 0, 0.2, 0)
						mutationLabel.BackgroundTransparency = 1
						mutationLabel.Font = Enum.Font.SourceSansBold
						mutationLabel.TextScaled = true

						-- Use the same format as permanent mutations
						mutationLabel.Text = "? " .. data.mutation .. " ?"

						-- Get color from MUTATION_COLORS table
					
						local mutColor = Color3.new(1, 1, 1)
						local mc = MUTATION_COLORS[data.mutation]

						-- Only apply the color if it is an actual Color3 (ignores strings like "Rainbow" and "YinYang")
						if mc and typeof(mc) == "Color3" then
							mutationLabel.TextColor3 = mc
						end

						mutationLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
						mutationLabel.TextStrokeTransparency = 0
						mutationLabel.LayoutOrder = 2

						local constraint = Instance.new("UITextSizeConstraint")
						constraint.MaxTextSize = 35
						constraint.MinTextSize = 2
						constraint.Parent = mutationLabel

						-- Parent it to the main billboard so the UIListLayout organizes it instantly
						mutationLabel.Parent = statsGUI

						-- Apply rainbow animation if needed
						if MUTATION_COLORS[data.mutation] == "Rainbow" then
							task.spawn(function()
								local hue = 0
								while mutationLabel and mutationLabel.Parent do
									hue = (hue + 0.01) % 1
									mutationLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
									task.wait(0.05)
								end
							end)
						elseif MUTATION_COLORS[data.mutation] == "YinYang" then
							-- Alternate the label too
							task.spawn(function()
								local flip = false
								while mutationLabel and mutationLabel.Parent do
									flip = not flip
									mutationLabel.TextColor3 = flip and Color3.new(1,1,1) or Color3.new(0,0,0)
									task.wait(0.5)
								end
							end)
						end
					end

					-- 3. Fire the GUI announcement to all players
					if announceRemote then
						announceRemote:FireAllClients(luckyRot.Name, data.mutation, data.color)
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
	print("??? Weather system started!")

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



print("? WeatherController loaded.")