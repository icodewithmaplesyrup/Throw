-- Put this in ServerScriptService/ShopSystem
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Sell prices based on individual brainrot name
local SELL_PRICES = {
	-- COMMON
	["Tralalero Tralala"] = 10000000,
	["Spioniro Golubiro"] = 750000,
	["Quivioli Ameleonni"] = 225000,
	["Strawberrelli Flamingelli"] = 275000,
	["Strawberry Elephant"] = 500000000000,
	["Ti Ti Ti Sahur"] = 37500,
	["Spaghetti Tualetti"] = 50000000000,
	["Salamino Penguino"] = 400000,
	["Rhino Toasterino"] = 450000,
	["Tric Trac Baraboom"] = 9000,
	["Torrtuginni Dragonfrutini"] = 120000000,
	["Sammyni Spyderini"] = 100000000,
	["Urubini Flamenguini"] = 35000000,
	["Unclito Samito"] = 20000000,
	["Trippi Troppi"] = 2000,
	["Te Te Te Sahur"] = 4000000,
	["Svinina Bombardino"] = 1200,
	["Ta Ta Ta Ta Sahur"] = 7500,
	["Sigma Girl"] = 340000,
	["Trulimero Trulicina"] = 20000,
	["Trenostruzzo Turbo 3000"] = 35000000,
	["Talpa Di Fero"] = 1000,
	["Tim Cheese"] = 500,
	["Trippi Troppi Troppa Trippa"] = 30000000,
	["Taco Lucky Block"] = 500000,
	["Tralaledon"] = 15000000000,
	["Tigrilini Watermelini"] = 1700000,
	["Zibra Zubra Zibralini"] = 1000000,
	["Tracoducotulu Delapeladustuz"] = 4200000,
	["Tralalita Tralala"] = 20000000,
	["Tigroligre Frutonni"] = 14000000,
	["Sigma Boy"] = 325000,
	["To to to Sahur"] = 550000000,
	["Tipi Topi Taco"] = 17500000,
	["Pot Hotspot"] = 500000000,
	["Tukanno Bananno"] = 22500000,
	["Tung Tung Tung Sahur"] = 2500000,
	["Secret Lucky Block"] = 750000000,
	["67"] = 2600000000,
	["Admin Lucky Block"] = 1000000000,
	["Agarrini la Palini"] = 160000000,
	["Alessio"] = 18000000,
	["Antonio"] = 6000000,
	["Avocadini Antilopini"] = 17500,
	["Avocadini Guffo"] = 35000,
	["Avocadorilla"] = 2000000,
	["Ballerina Cappuccina"] = 100000,
	["Ballerino Lololo"] = 45000000,
	["Bambini Crostini"] = 225000,
	["Bananita Dolphinita"] = 25000,
	["Bandito Axolito"] = 12500,
	["Bandito Bobritto"] = 4500,
	["Bisonte Giuppitere"] = 75000000,
	["Blackhole Goat"] = 140000000,
	["Blueberrinni Octopusini"] = 250000,
	["Bombardiro Crocodilo"] = 500000,
	["Bombombini Gusini"] = 1000000,
	["Boneca Ambalabu"] = 5000,
	["Brainrot God Lucky Block"] = 5000000,
	["Brr Brr Patapim"] = 15000,
	["Brr es Teh Patipum"] = 65000000,
	["Brri Brri Bicus Dicus Bombicus"] = 30000,
	["Bulbito Bandito Traktorito"] = 48000000,
	["Burbaloni Loliloli"] = 100000,
	["Cacasito Satalito"] = 125000,
	["Cacto Hipopotamo"] = 6500,
	["Cappuccino Assassino"] = 10000,
	["Caramello Filtrello"] = 255000,
	["Carloo"] = 4500000,
	["Carrotini Brainini"] = 4700000,
	["Cavallo Virtuoso"] = 2500000,
	["Celularcini Viciosini"] = 10000000000,
	["Chachechi"] = 150000000,
	["Chef Crabracadabra"] = 150000,
	["Chicleteira Bicicleteira"] = 3500000,
	["Chihuanini Taconini"] = 8500000,
	["Chimpanzini Bananini"] = 50000,
	["Cocofanto Elefanto"] = 5000000,
	["Crabbo Limonetta"] = 1250000,
	["Dragon Cannelloni"] = 100000000000,
	["Dug dug dug"] = 255000,
	["Dul Dul Dul"] = 130000000,
	["Esok Sekolah"] = 3000000,
	["Espresso Signora"] = 15000000,
	["Extinct Ballerina"] = 30000000,
	["Extinct Matteo"] = 250000000,
	["Extinct Tralalero"] = 175000000,
	["Fluriflura"] = 750,
	["Fragola La La La"] = 180000000,
	["Frigo Camelo"] = 350000,
	["Ganganzelli Trulala"] = 3500000,
	["Gangster Footera"] = 4000,
	["Garama and Madundung"] = 40000000000,
	["Gattatino Nyanino"] = 7500000,
	["Gattito Tacoto"] = 40000000,
	["Girafa Celestre"] = 7500000,
	["Glorbo Fruttodrillo"] = 200000,
	["Gorillo Watermelondrillo"] = 3000000,
	["Graipuss Medussi"] = 400000000,
	["Guerriro Digitale"] = 1000000000,
	["Job Job Job Sahur"] = 350000000,
	["Karkerkar Kurkur"] = 550000,
	["Ketchuru and Musturu"] = 30000000000,
	["Ketupat Kepat"] = 25000000000,
	["La Cucaracha"] = 220000000,
	["La Extinct Grande"] = 235000000,
	["La Grande Combinasion"] = 750000000,
	["La Karkerkar Combinasion"] = 7500000000,
	["La Sahur Combinasion"] = 550000000,
	["La Vacca Saturno Saturnita"] = 110000000,
	["Las Capuchinas"] = 185000,
	["Las Sis"] = 8000000000,
	["Las Tralaleritas"] = 650000,
	["Las Vaquitas Saturnitas"] = 60000,
	["Lerulerulerule"] = 3500000,
	["Lionel Cactuseli"] = 175000,
	["Lirilì Larilà"] = 250,
	["Los Bombinitos"] = 60000000,
	["Los Bros"] = 12000000000,
	["Los Chicleteiras"] = 4500000,
	["Los Combinasionas"] = 15000000,
	["Los Crocodillitos"] = 12500000,
	["Los Hotspotsitos"] = 25000000,
	["Los Matteos"] = 100000000,
	["Los Noobinis"] = 4300000,
	["Los Nooo My Hotspotsitos"] = 3500000000,
	["Los Orcalitos"] = 45000000,
	["Los Spyderinis"] = 200000000,
	["Los Tacoritas"] = 16500000,
	["Los Tipi Tacos"] = 260000,
	["Los Tralaleritos"] = 300000000,
	["Los Tungtungtungcitos"] = 50000000,
	["Matteo"] = 10000000,
	["Mythic Lucky Block"] = 2500000,
	["Noobini Pizzanini"] = 25,
	["Nuclearo Dinossauro"] = 5000000000,
	["Odin Din Din Dun"] = 16000000,
	["Orangutini Ananassini"] = 400000,
	["Orcalero Orcala"] = 25000000,
	["Pakrahmatmamat"] = 55000000,
	["Pandaccini Bananini"] = 300000,
	["Penguino Cocosino"] = 45000,
	["Perochello Lemonchello"] = 27500,
	["Piccione Macchina"] = 65000000,
	["Pipi Avocado"] = 9500,
	["Pipi Corni"] = 1700,
	["Pipi Kiwi"] = 1500,
	["Pipi Potato"] = 265000,
}

	-- Reference to brainrot folder
	local BrainrotPackFolder = ReplicatedStorage:WaitForChild("Brainrot pack1", 10)

	-- Create RemoteEvent for selling
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
	end

	local sellBrainrotEvent = remoteEvents:FindFirstChild("SellBrainrotEvent")
	if not sellBrainrotEvent then
		sellBrainrotEvent = Instance.new("RemoteEvent")
		sellBrainrotEvent.Name = "SellBrainrotEvent"
		sellBrainrotEvent.Parent = remoteEvents
	end

	-- Function to check if player has a valid brainrot equipped
	local function getEquippedBrainrot(player)
		if not player.Character then return nil end
		local tool = player.Character:FindFirstChildOfClass("Tool")
		if not tool or not BrainrotPackFolder then return nil end

		-- Verify it's actually a brainrot from our pack
		for _, item in pairs(BrainrotPackFolder:GetChildren()) do
			if item.Name == tool.Name then
				return tool
			end
		end
		return nil
	end

	-- Function to sell brainrot
	local function sellBrainrot(player)
		local brainrot = getEquippedBrainrot(player)

		if not brainrot then
			return false, "You need to hold a Brainrot to sell!", 0
		end

		-- Get sell price by brainrot name
		local brainrotName = brainrot.Name
		local sellPrice = SELL_PRICES[brainrotName]

		if not sellPrice then
			warn("?? '" .. brainrotName .. "' not found in SELL_PRICES. Defaulting to $1.")
			sellPrice = 1
		end

		local rarity = brainrot:GetAttribute("Rarity") or "Unknown"

		-- Give player money
		local moneyRaw = player:FindFirstChild("MoneyRaw")
		if not moneyRaw then
			return false, "Money system not found!", 0
		end

		moneyRaw.Value = moneyRaw.Value + sellPrice

		-- Destroy the brainrot tool
		brainrot:Destroy()

		print("?? " .. player.Name .. " sold " .. brainrotName .. " (" .. rarity .. ") for $" .. sellPrice)

		return true, "Sold " .. brainrotName .. " for $" .. sellPrice .. "!", sellPrice, brainrotName, rarity
	end

	-- Handle sell requests
	sellBrainrotEvent.OnServerEvent:Connect(function(player)
		print("?? Sell request from " .. player.Name)
		local success, message, amount, name, rarity = sellBrainrot(player)
		print("?? Sending result to client:", success, message, amount)
		sellBrainrotEvent:FireClient(player, success, message, amount, name, rarity)
	end)

	-- Setup shop ProximityPrompts in workspace
	local function setupShopPrompt(shopPart)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ShopPrompt"
		prompt.ActionText = "Sell Brainrot"
		prompt.ObjectText = "Shop"
		prompt.MaxActivationDistance = 10
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = shopPart

		prompt.Triggered:Connect(function(player)
			local success, message, amount, name, rarity = sellBrainrot(player)
			sellBrainrotEvent:FireClient(player, success, message, amount, name, rarity)
		end)

		print("? Shop prompt added to " .. shopPart:GetFullName())
	end

	-- Auto-find and setup shop parts (any part named "BrainrotSellLocation" or with "IsBrainrotShop" attribute)
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name == "BrainrotSellLocation" or obj:GetAttribute("IsBrainrotShop") == true then
				setupShopPrompt(obj)
			end
		end
	end

	print("? Shop System loaded!")