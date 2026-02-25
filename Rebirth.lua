	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local rebirthevent = ReplicatedStorage.RemoteEvents:WaitForChild("rebirthevent")

	-- CONFIGURATION
	local BASE_REBIRTH_COST = 100000 -- First rebirth cost
	local COST_MULTIPLIER = 1.5      -- Multiplier per rebirth (exponential growth)

	-- Cost formula options (choose one by uncommenting):
	local function calculateCost(rebirthCount)
		-- OPTION 1: Exponential (recommended for simulators)
		-- Gets expensive quickly: 100k, 150k, 225k, 337.5k, 506.25k...
		return math.floor(BASE_REBIRTH_COST * (COST_MULTIPLIER ^ rebirthCount))

		-- OPTION 2: Linear
		-- Steady increase: 100k, 200k, 300k, 400k...
		-- return BASE_REBIRTH_COST * (rebirthCount + 1)

		-- OPTION 3: Quadratic
		-- Moderate scaling: 100k, 200k, 400k, 800k, 1.6M...
		-- return BASE_REBIRTH_COST * ((rebirthCount + 1) ^ 2)

		-- OPTION 4: Fibonacci-style
		-- Unique progression
		-- if rebirthCount == 0 then return BASE_REBIRTH_COST end
		-- if rebirthCount == 1 then return BASE_REBIRTH_COST * 2 end
		-- return calculateCost(rebirthCount - 1) + calculateCost(rebirthCount - 2)
	end

	rebirthevent.OnServerEvent:Connect(function(player)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		local moneyRaw = player:FindFirstChild("MoneyRaw")
		local rebirths = leaderstats:FindFirstChild("Rebirths")

		if not moneyRaw or not rebirths then return end

		-- Calculate current cost based on rebirth count
		local currentCost = calculateCost(rebirths.Value)

		-- Check if player can afford it
		if moneyRaw.Value >= currentCost then
			-- Reset money and increment rebirths
			moneyRaw.Value = 0
			rebirths.Value = rebirths.Value + 1

			print(player.Name .. " rebirthed! Now at: " .. rebirths.Value .. " rebirths")

			-- Send success back to client (for UI feedback)
			rebirthevent:FireClient(player, true, rebirths.Value)
		else
			-- Send failure back to client
			warn(player.Name .. " tried to rebirth but needs $" .. currentCost .. " (has $" .. moneyRaw.Value .. ")")
			rebirthevent:FireClient(player, false, currentCost)
		end
	end)