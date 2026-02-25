local ReplicatedStorage = game:GetService("ReplicatedStorage")
local flyEvent = ReplicatedStorage:FindFirstChild("AdminFlyEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
flyEvent.Name = "AdminFlyEvent"

local playersWithPerms = {}

flyEvent.OnServerEvent:Connect(function(admin, targetName)
	for _, p in pairs(game.Players:GetPlayers()) do
		if string.sub(p.Name:lower(), 1, #targetName) == targetName:lower() then

			if playersWithPerms[p.UserId] then
				-- PLAYER ALREADY HAS PERMS: Remove them
				playersWithPerms[p.UserId] = nil
				flyEvent:FireClient(p, false) -- Send 'false' to disable
				print("?? SERVER: Removed fly perms from " .. p.Name)
			else
				-- PLAYER DOES NOT HAVE PERMS: Give them
				playersWithPerms[p.UserId] = true
				flyEvent:FireClient(p, true) -- Send 'true' to enable
				print("? SERVER: Gave fly perms to " .. p.Name)
			end
			break
		end
	end
end)

-- Clean up table when players leave
game.Players.PlayerRemoving:Connect(function(player)
	playersWithPerms[player.UserId] = nil
end)
