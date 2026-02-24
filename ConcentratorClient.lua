-- ================================================================
--  WeatherConcentratorClient  (LocalScript)
--  Place inside StarterPlayerScripts (or StarterCharacterScripts)
--
--  Listens for ConcentratorResult and ConcentratorBroadcast remote
--  events fired by WeatherConcentratorSystem and shows on-screen
--  notifications — exactly like the slot system's client feedback.
-- ================================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes             = ReplicatedStorage:WaitForChild("RemoteEvents")
local ConcentratorResult  = Remotes:WaitForChild("ConcentratorResult")
local ConcentratorBroadcast = Remotes:WaitForChild("ConcentratorBroadcast")

-- ================================================================
--  NOTIFICATION UI
--  Two separate notification tracks:
--    Personal  — craft result shown only to the player who triggered
--    Discovery — server-wide broadcast when a first discovery happens
-- ================================================================

local function createNotifGui(name)
	-- Destroy old one if it exists (e.g. character respawn)
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name              = name
	sg.ResetOnSpawn      = false
	sg.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
	sg.IgnoreGuiInset    = true
	sg.Parent            = playerGui

	local frame = Instance.new("Frame")
	frame.Name              = "Frame"
	frame.AnchorPoint       = Vector2.new(0.5, 0)
	frame.Position          = UDim2.new(0.5, 0, -0.15, 0)  -- starts off-screen above
	frame.Size              = UDim2.new(0.55, 0, 0.08, 0)
	frame.BackgroundColor3  = Color3.fromRGB(15, 15, 25)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel   = 0
	frame.Parent            = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color     = Color3.fromRGB(100, 80, 255)
	stroke.Thickness = 2
	stroke.Parent    = frame

	local label = Instance.new("TextLabel")
	label.Name                  = "Message"
	label.Size                  = UDim2.new(1, -20, 1, 0)
	label.Position              = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3            = Color3.fromRGB(255, 255, 255)
	label.TextScaled            = true
	label.Font                  = Enum.Font.FredokaOne
	label.TextXAlignment        = Enum.TextXAlignment.Center
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3      = Color3.new(0, 0, 0)
	label.Parent                = frame

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = 26
	constraint.MinTextSize = 10
	constraint.Parent      = label

	sg.Enabled = false
	return sg, frame, label
end

-- -- Personal result notification (centre-top) --------------------
local personalGui, personalFrame, personalLabel = createNotifGui("ConcentratorPersonalNotif")

-- -- Discovery broadcast notification (slightly lower, gold border) -
local discoveryGui, discoveryFrame, discoveryLabel = createNotifGui("ConcentratorDiscoveryNotif")

-- Make discovery notification visually distinct
discoveryFrame.Size              = UDim2.new(0.7, 0, 0.1, 0)
discoveryFrame.BackgroundColor3  = Color3.fromRGB(20, 10, 5)
local dStroke = discoveryFrame:FindFirstChildOfClass("UIStroke")
if dStroke then dStroke.Color = Color3.fromRGB(255, 200, 0) end

-- ================================================================
--  SHOW NOTIFICATION  (slide down, hold, slide up)
-- ================================================================
local function showNotif(sg, frame, label, message, color, holdTime)
	-- Cancel any running hide task for this gui
	local existingTag = sg:GetAttribute("HideTaskRunning")
	sg:SetAttribute("HideTaskRunning", false)

	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Text       = message
	sg.Enabled       = true

	-- Reset to off-screen
	frame.Position = UDim2.new(0.5, 0, -0.15, 0)

	-- Slide in
	TweenService:Create(frame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.04, 0) }
	):Play()

	sg:SetAttribute("HideTaskRunning", true)
	task.spawn(function()
		task.wait(holdTime or 3)
		-- Only hide if no newer call has taken over
		if not sg:GetAttribute("HideTaskRunning") then return end

		TweenService:Create(frame,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, -0.15, 0) }
		):Play()
		task.wait(0.4)
		sg.Enabled = false
	end)
end

-- ================================================================
--  PERSONAL RESULT  — fired only to this player
--  (success: bool, message: string, discoveryBonus: number|nil)
-- ================================================================
ConcentratorResult.OnClientEvent:Connect(function(success, message, discoveryBonus)
	if success then
		local color = discoveryBonus
			and Color3.fromRGB(255, 215, 0)    -- gold for discoveries
			or  Color3.fromRGB(100, 255, 150)  -- green for normal fuse
		showNotif(personalGui, personalFrame, personalLabel, message, color, 4)
	else
		showNotif(personalGui, personalFrame, personalLabel, message,
			Color3.fromRGB(255, 80, 80), 3)    -- red for failures
	end
end)

-- ================================================================
--  DISCOVERY BROADCAST  — fired to everyone when someone discovers
--  (playerName, blendedName, brainrotName, bonusAmount, depth)
-- ================================================================
ConcentratorBroadcast.OnClientEvent:Connect(function(discovererName, blendedName, brainrotName, bonus, depth)
	-- Don't double-show for the discoverer (they already got a personal notif)
	if discovererName == player.Name then return end

	local msg = string.format(
		"?? %s discovered '%s' (depth %d) and earned $%s!",
		discovererName,
		blendedName,
		depth,
		string.format("%d", bonus)
	)

	showNotif(discoveryGui, discoveryFrame, discoveryLabel,
		msg, Color3.fromRGB(255, 215, 0), 5)
end)

-- ================================================================
--  CONCENTRATOR COST PREVIEW
--  Updates the ProximityPrompt subtitle with the live cost so
--  players know what they'll pay before they commit.
-- ================================================================
local ConcentratorInfo = Remotes:WaitForChild("ConcentratorInfo", 5)

if ConcentratorInfo then
	-- Poll every 2 seconds so it stays current as weather changes
	-- and as the player swaps tools
	task.spawn(function()
		while true do
			task.wait(2)
			local char = player.Character
			if char then
				local ok, info = pcall(function()
					return ConcentratorInfo:InvokeServer()
				end)
				if ok and info then
					-- Find the concentrator's ProximityPrompt in the world
					-- and update its ActionText with the cost
					local concentrator = workspace:FindFirstChild("WeatherConcentrator", true)
					if concentrator then
						local prompt = concentrator:FindFirstChildWhichIsA("ProximityPrompt", true)
						if prompt then
							if info.activeMutation then
								prompt.ActionText = string.format(
									"Concentrate  ($%s)",
									string.format("%d", info.cost)
								)
							else
								prompt.ActionText = "Concentrate"
							end
						end
					end
				end
			end
		end
	end)
end