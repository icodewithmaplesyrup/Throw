-- Put this in StarterPlayer > StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local placeBrainrotEvent = remoteEvents:WaitForChild("PlaceBrainrotEvent")
local collectIncomeEvent = remoteEvents:WaitForChild("CollectIncomeEvent")

-- Listen for place brainrot responses (just console logging now)
placeBrainrotEvent.OnClientEvent:Connect(function(success, message)
	if success then
		print("? " .. message)
	else
		print("?"  .. message)
	end
end)

-- Listen for collect income responses (just console logging now)
collectIncomeEvent.OnClientEvent:Connect(function(success, message, amount)
	if success then
		print("?? " .. message)
	else
		print("? " .. message)
	end
end)

print("? Brainrot Slot Client System loaded!")