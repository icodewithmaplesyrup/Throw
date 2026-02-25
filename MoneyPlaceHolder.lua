local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))

local function setupLeaderstats(player)
	-- leaderstats folder
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	-- REAL money (not on leaderboard)
	local moneyRaw = player:FindFirstChild("MoneyRaw")
	if not moneyRaw then
		moneyRaw = Instance.new("NumberValue")
		moneyRaw.Name = "MoneyRaw"
		moneyRaw.Value = 0
		moneyRaw.Parent = player -- IMPORTANT: not inside leaderstats
	end

	-- DISPLAY money (on leaderboard)
	local moneyDisplay = leaderstats:FindFirstChild("Money")
	if not moneyDisplay then
		moneyDisplay = Instance.new("StringValue")
		moneyDisplay.Name = "Money" -- this is what the board shows
		moneyDisplay.Value = "0"
		moneyDisplay.Parent = leaderstats
	end

	local function updateDisplay()
		moneyDisplay.Value = NumberFormat.format(moneyRaw.Value)
	end

	updateDisplay()
	moneyRaw:GetPropertyChangedSignal("Value"):Connect(updateDisplay)

	-- Skyscraper Height
	local skyscraperHeight = leaderstats:FindFirstChild("Skyscraper Height")
	if not skyscraperHeight then
		skyscraperHeight = Instance.new("NumberValue")
		skyscraperHeight.Name = "Skyscraper Height"
		skyscraperHeight.Value = 1
		skyscraperHeight.Parent = leaderstats
	end

	-- Rebirths
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if not rebirths then
		rebirths = Instance.new("NumberValue")
		rebirths.Name = "Rebirths"
		rebirths.Value = 0
		rebirths.Parent = leaderstats
	end
end

Players.PlayerAdded:Connect(setupLeaderstats)
for _, player in ipairs(Players:GetPlayers()) do
	setupLeaderstats(player)
end