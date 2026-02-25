-- Put this in StarterPlayer > StarterPlayerScripts > TestPlaceBrainrot
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvent
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local placeBrainrotEvent = remoteEvents:WaitForChild("PlaceBrainrotEvent")

-- Create a simple test GUI

local gui = playerGui:WaitForChild("TestPlaceGui")
local placeButton = gui.PlaceButton

-- Function to find the nearest slot
local function findNearestSlot()
	local character = player.Character
	if not character or not character.PrimaryPart then return nil end

	local playerPos = character.PrimaryPart.Position
	local nearestSlot = nil
	local nearestDistance = 50 -- Max distance

	local basesFolder = Workspace:FindFirstChild("BrainrotBases")
	if not basesFolder then 
		warn("BrainrotBases folder not found!")
		return nil 
	end

	for _, base in pairs(basesFolder:GetChildren()) do
		if base:IsA("Model") then
			for _, slot in pairs(base:GetChildren()) do
				if slot:IsA("Model") and slot.Name:match("Slot") then
					local displayPos = slot:FindFirstChild("DisplayPosition")
					if displayPos then
						local distance = (displayPos.Position - playerPos).Magnitude
						if distance < nearestDistance then
							nearestDistance = distance
							nearestSlot = slot
						end
					end
				end
			end
		end
	end

	return nearestSlot, nearestDistance
end

-- Button click handler
placeButton.MouseButton1Click:Connect(function()
	print("?? Place button clicked!")

	local nearestSlot, distance = findNearestSlot()

	if nearestSlot then
		print("?? Nearest slot:", nearestSlot.Name, "| Distance:", math.floor(distance), "studs")
		placeButton.Text = "PLACING..."
		placeButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)

		-- Fire to server
		placeBrainrotEvent:FireServer(nearestSlot)

		task.wait(0.5)
		placeButton.Text = "PLACE BRAINROT"
		placeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
	else
		print("? No slot nearby (must be within 50 studs)")
		placeButton.Text = "NO SLOT NEARBY!"
		placeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)

		task.wait(1)
		placeButton.Text = "PLACE BRAINROT"
		placeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
	end
end)

print("? Test Place Brainrot GUI loaded! Click the blue button to place.")