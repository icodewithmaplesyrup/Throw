local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local addMoneyEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AddMoneyRequest")

-- ??? Helper: Check Developer Status
local function isDeveloper(player)
	-- Always allow in Studio
	if RunService:IsStudio() then
		return true
	end

	-- Allow if you are the owner OR if your ID matches
	return player.UserId == game.CreatorId or player.UserId == 10378926133 -- Put your ID here
end

local function onAddMoneyRequest(player, amount, targetUsername)
	-- ??? SECURITY: Check if player is developer
	if not isDeveloper(player) then
		warn("? Security: " .. player.Name .. " attempted to add money but is not a developer")
		return
	end

	-- Validate the input
	if type(amount) ~= "number" or amount <= 0 then
		warn("? Invalid amount requested by " .. player.Name .. ": " .. tostring(amount))
		return
	end

	-- Determine target player (default to requester if no username provided)
	local targetPlayer = player
	if targetUsername and targetUsername ~= "" then
		-- Find the target player by name
		for _, p in Players:GetPlayers() do
			if string.lower(p.Name) == string.lower(targetUsername) then
				targetPlayer = p
				break
			end
		end
	end

	-- Find and update the target player's money
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats.Parent:FindFirstChild("MoneyRaw")

	if money then
		money.Value = money.Value + amount
		print("? Added " .. amount .. " money to " .. targetPlayer.Name .. (targetPlayer ~= player and " (requested by " .. player.Name .. ")" or ""))
	else
		warn("? Could not find Money leaderstat for " .. targetPlayer.Name)
	end
end

-- Connect the remote event
addMoneyEvent.OnServerEvent:Connect(onAddMoneyRequest)