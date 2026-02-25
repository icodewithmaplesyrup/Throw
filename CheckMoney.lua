local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PurchaseEvent = ReplicatedStorage.RemoteEvents:WaitForChild("Purchasecoil") -- Use one event for the transaction
local ServerStorage = game:GetService("ServerStorage")

-- Configuration Table (Easy to add more items later!)
local ItemPrices = {
	["SpeedCoil"] = 500,
	["SuperSpeedCoil"] = 800 
}

PurchaseEvent.OnServerEvent:Connect(function(player, itemName)
	local price = ItemPrices[itemName]
	local tool = ServerStorage:WaitForChild(itemName)
	-- 1. Validate the item exists
	if not price then return end 

	-- 2. Secure Money Check
	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats.Parent:WaitForChild("MoneyRaw")

	if money.Value >= price then
		-- 3. The Transaction
		money.Value = money.Value - price -- Subtract money
		tool:Clone().Parent = player.Backpack -- Give the tool

		-- 4. Tell the Client it succeeded
		PurchaseEvent:FireClient(player, true, itemName)
		print(player.Name .. " bought " .. itemName)
	else
		-- 5. Tell the Client it failed
		PurchaseEvent:FireClient(player, false, "Insufficient Funds")
	end
end)