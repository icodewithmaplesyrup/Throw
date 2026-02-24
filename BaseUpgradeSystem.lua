print("??? BaseUpgradeSystem (Replicate Mode) starting...")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Ensure Remotes Exist
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
remoteEvents.Name = "RemoteEvents"

local upgradeBaseEvent = remoteEvents:FindFirstChild("UpgradeBaseEvent") or Instance.new("RemoteEvent", remoteEvents)
upgradeBaseEvent.Name = "UpgradeBaseEvent"

local incomingEvent = remoteEvents:FindFirstChild("UpgradeBase") or Instance.new("RemoteEvent", remoteEvents)
incomingEvent.Name = "UpgradeBase"

-- ==========================================================
-- ?? CONFIGURATION
-- ==========================================================
local BASES_FOLDER_NAME = "BrainrotBases"
local TEMPLATE_NAME = "SecondFloorReplicate" -- Name of the model to clone

local UPGRADE_CONFIG = {
	BaseCost = 1000,
	Multiplier = 1.5,
	Exponent = 1.3
}

-- ??? FLOOR POSITIONING CONFIGURATION
-- Controls the position of new floors relative to the base center

-- Vertical spacing (Y-axis)
-- Positive number = gap between floors
-- Negative number = floors overlap/squish together
-- 0 = floors touch perfectly (edge to edge)
local FLOOR_SPACING = -24.75

-- Horizontal offset (X-axis)
-- Positive = shift right, Negative = shift left
-- 0 = centered on base X position
local FLOOR_OFFSET_X = 4.8

-- Horizontal offset (Z-axis)
-- Positive = shift forward, Negative = shift backward
-- 0 = centered on base Z position
local FLOOR_OFFSET_Z = 5

-- ==========================================================
-- VARIABLES
-- ==========================================================
local BASES_FOLDER = Workspace:WaitForChild(BASES_FOLDER_NAME, 5)
local FLOOR_TEMPLATE = Workspace:WaitForChild(TEMPLATE_NAME, 5)

if not BASES_FOLDER or not FLOOR_TEMPLATE then
	warn("? CRITICAL ERROR: Could not find 'BrainrotBases' folder or 'SecondFloorReplicate' model!")
	return
end

-- Track data
local baseData = {} 
-- Structure: 
-- baseData[baseModel] = {
--     Level = 1,
--     TopFloorModel = baseModel (Initially the base itself)
-- }

-- ==========================================================
-- ?? MATH HELPER FUNCTIONS
-- ==========================================================

local function calculateUpgradeCost(currentLevel)
	local cost = UPGRADE_CONFIG.BaseCost 
		* (UPGRADE_CONFIG.Multiplier ^ (currentLevel - 1)) 
		* (currentLevel ^ UPGRADE_CONFIG.Exponent)
	return math.floor(cost)
end

local function getBaseInfo(base)
	if not baseData[base] then
		baseData[base] = {
			Level = 1,
			TopFloorModel = base
		}
	end
	return baseData[base]
end

-- ==========================================================
-- ?? VISUALS
-- ==========================================================

local function updateSignVisuals(base)
	local info = getBaseInfo(base)
	local cost = calculateUpgradeCost(info.Level)
	local text = "Upgrade to Floor " .. (info.Level + 1) .. "\n$" .. cost

	local upgradeSign = base:FindFirstChild("UpgradeSign")
	if upgradeSign then
		-- Update SurfaceGui
		local surfaceGui = upgradeSign:FindFirstChildWhichIsA("SurfaceGui", true)
		if surfaceGui then
			local label = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)
			if label then label.Text = text end
		end

		-- Update ProximityPrompt
		local prompt = upgradeSign:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			prompt.ObjectText = "$" .. cost
			prompt.ActionText = "Upgrade (Lvl " .. (info.Level + 1) .. ")"
			prompt.Enabled = true
		end
	end
end

-- ==========================================================
-- ??? CORE UPGRADE LOGIC
-- ==========================================================

local function findBaseOwnedBy(player)
	for _, base in pairs(BASES_FOLDER:GetChildren()) do
		local ownerVal = base:FindFirstChild("Owner")
		if ownerVal and ownerVal.Value == player.Name then
			return base
		end
	end
	return nil
end

local function upgradeBase(player, base)
	local info = getBaseInfo(base)
	local cost = calculateUpgradeCost(info.Level)

	-- 1. Check Money
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and (leaderstats.Parent:FindFirstChild("MoneyRaw") or leaderstats:FindFirstChild("Cash"))

	if not money then return false, "No money found!" end
	if money.Value < cost then return false, "Need $"..cost end

	-- 2. Prepare the New Floor
	local currentTop = info.TopFloorModel
	local newFloor = FLOOR_TEMPLATE:Clone()
	local nextLevel = info.Level + 1

	-- 3. Calculate Stacking Position
	local currentCF, currentSize = currentTop:GetBoundingBox()
	local newCF, newSize = newFloor:GetBoundingBox()
	local baseCF = base:GetBoundingBox() -- This is the "Anchor" rotation

	-- Calculate Height: Top of old floor + Half height of new floor + Floor Spacing
	local stackY = (currentSize.Y / 2) + (newSize.Y / 2) + FLOOR_SPACING

	-- Calculate Target Position with offsets:
	-- X = Base center + X offset
	-- Y = Calculated stack height above current top floor
	-- Z = Base center + Z offset
	local targetY = currentCF.Position.Y + stackY
	local targetPos = Vector3.new(
		baseCF.Position.X + FLOOR_OFFSET_X, 
		targetY, 
		baseCF.Position.Z + FLOOR_OFFSET_Z
	)

	-- ---------------------------------------------------------
	-- ?? CRITICAL FIX: FORCE ROTATION TO MATCH BASE ??
	-- ---------------------------------------------------------
	newFloor:PivotTo(CFrame.new(targetPos) * baseCF.Rotation)

	-- 4. Clean up the New Floor
	newFloor.Name = base.Name .. "_Floor" .. nextLevel
	for _, child in pairs(newFloor:GetChildren()) do
		if child.Name == "UpgradeSign" or child.Name == "Owner" or child:IsA("Script") then
			child:Destroy()
		end
	end

	newFloor.Parent = BASES_FOLDER

	-- 5. Finalize Transaction
	money.Value -= cost
	info.Level = nextLevel
	info.TopFloorModel = newFloor

	local skyHeight = leaderstats:FindFirstChild("Skyscraper Height")
	if skyHeight then skyHeight.Value = nextLevel end

	updateSignVisuals(base)

	print("? " .. player.Name .. " stacked floor " .. nextLevel .. " (Offset: X=" .. FLOOR_OFFSET_X .. ", Y=" .. FLOOR_SPACING .. ", Z=" .. FLOOR_OFFSET_Z .. ")")
	return true, "Upgraded to Floor " .. nextLevel .. "!", nextLevel
end

-- ==========================================================
-- ?? EVENT LISTENERS
-- ==========================================================

incomingEvent.OnServerEvent:Connect(function(player)
	local playerBase = findBaseOwnedBy(player)
	if not playerBase then
		upgradeBaseEvent:FireClient(player, false, "You don't own a base!")
		return
	end

	-- Debounce check could go here
	local success, msg = upgradeBase(player, playerBase)
	upgradeBaseEvent:FireClient(player, success, msg)
end)

-- Initialize Signs on Load
for _, base in pairs(BASES_FOLDER:GetChildren()) do
	if base:IsA("Model") then
		updateSignVisuals(base)
	end
end