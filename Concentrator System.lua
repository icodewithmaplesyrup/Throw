-- ================================================================
--  WeatherConcentratorSystem  (ServerScriptService)
--
--  Players approach the WeatherConcentrator and trigger the
--  ProximityPrompt while holding a Brainrot tool.  It fuses the
--  currently active weather mutation onto that brainrot, stacking
--  infinitely.  Gemini blends all accumulated mutation names into
--  one creative label.  The first player globally to reach any
--  specific mutation combo earns a discovery bonus that scales
--  with how many mutations deep the combo is.
--
--  SETUP CHECKLIST
--  --------------------------------------------------------------
--  1. Enable HttpService        (Game Settings ? Security)
--  2. Enable DataStoreService   (Game Settings ? Security)
--  3. Place a Model called "WeatherConcentrator" in Workspace
--       +- PrimaryPart  (BasePart — the glowing pedestal)
--          +- ProximityPrompt  (direct child of PrimaryPart)
--             If absent, one is created automatically.
--  4. Paste your Gemini API key into CONFIG.GEMINI_API_KEY.
--     For production: store it in a private ModuleScript under
--     ServerScriptService so it is never replicated to clients.
--  5. RECOMMENDED: Move BRAINROT_INCOME into a shared ModuleScript
--     (ReplicatedStorage/BrainrotIncomeData) and require it here
--     AND in BrainrotSlotSystem — keeps the two in sync.
-- ================================================================

local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local DataStoreService  = game:GetService("DataStoreService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeatherSystem = require(ReplicatedStorage:WaitForChild("WeatherSystem"))

-- ================================================================
--  CONFIG
-- ================================================================
local CONFIG = {
	-- -- Gemini ---------------------------------------------------
	GEMINI_API_KEY  = "yours here",
	GEMINI_MODEL    = "gemini-2.0-flash",

	-- -- Craft cost -----------------------------------------------
	COST_SECONDS    = 45,
	MIN_COST        = 500,

	-- -- Discovery rewards ----------------------------------------
	-- depth 1 ? 5,000   depth 2 ? 15,000   depth 3 ? 45,000  etc.
	BASE_DISCOVERY_REWARD = 5000,
	DEPTH_MULTIPLIER      = 3.0,

	-- -- Misc -----------------------------------------------------
	PLAYER_COOLDOWN          = 8,
	CONCENTRATOR_MODEL_NAME  = "WeatherConcentrator",
	DS_DISCOVERIES           = "ConcentratorDiscoveries_v2",
}

-- ================================================================
--  INCOME TABLE
-- ================================================================
local BRAINROT_INCOME = {
	["Noobini Pizzanini"]=1,["Lirili Larila"]=3,["Tim Cheese"]=5,
	["FluriFlura"]=7,["Talpa Di Fero"]=9,["Svinina Bombardino"]=10,
	["Noobini Santanini"]=11,["Racooni Jandelini"]=12,["Pipi Kiwi"]=13,
	["Tartaragno"]=13,["Pipi Corni"]=14,["Trippi Troppi"]=15,
	["Gangster Footera"]=30,["Bandito Bobritto"]=35,["Boneca Ambalabu"]=40,
	["Cacto Hipopotamo"]=50,["Ta Ta Ta Ta Sahur"]=55,["Tric Trac Baraboom"]=65,
	["Frogo Elfo"]=67,["Pipi Avocado"]=70,["Pinealotto Fruttarino"]=75,
	["Cappuccino Assassino"]=75,["Bandito Axolito"]=90,["Brr Brr Patapim"]=100,
	["Avocadini Antilopini"]=115,["Trulimero Trulicina"]=125,["Bambini Crostini"]=135,
	["Malame Amarele"]=140,["Bananita Dolphinita"]=150,["Perochello Lemonchello"]=160,
	["Brri Brri Bicus Dicus Bombicus"]=175,["Avocadini Guffo"]=225,
	["Ti Ti Ti Sahur"]=225,["Mangolini Parrocini"]=235,["Frogatto Piratto"]=240,
	["Salamino Penguino"]=250,["Doi Doi Do"]=260,["Penguin Tree"]=270,
	["Wombo Rollo"]=275,["Penguino Cocosino"]=300,["Mummio Rappito"]=325,
	["Chimpanzini Bananini"]=300,["Tirilikalika Tirilikalako"]=450,
	["Ballerina Cappuccina"]=500,["Burbaloni Loliloli"]=600,
	["Chef Crabracadabra"]=600,["Lionel Cactuseli"]=650,
	["Glorbo Fruttodrillo"]=750,["Quivoli Ameleoni"]=900,
	["Blueberrini Octopusini"]=1000,["Caramello Filtrello"]=1000,
	["Pipi Potato"]=1100,["Strawberrelli Flamingelli"]=1100,
	["Cocosini Mama"]=1200,["Pandaccini Bananini"]=1250,["Quackula"]=1200,
	["Pi Pi Watermelon"]=1300,["Signore Carapace"]=1300,["Sigma Boy"]=1350,
	["Chocco Bunny"]=1400,["Puffaball"]=1500,["Sigma Girl"]=1800,
	["Buho de Fuego"]=1800,["Frigo Camelo"]=1900,
	["Orangutini Ananassini"]=2000,["Rhino Toasterino"]=2100,
	["Bombardiro Crocodilo"]=2500,["Spioniro Golubiro"]=3500,
	["Bangangini Gusini"]=5000,["Zibra Zubra Zibralini"]=6000,
	["Tigrilini Watermelini"]=6500,["Avocadorilla"]=7000,
	["Cavallo Virtuoso"]=7500,["Gorillo Subwoofero"]=7700,
	["Gorillo Watermelondrillo"]=8000,["Stoppo Luminino"]=8000,
	["Ganganzelli Trulala"]=9000,["Lerulerulerule"]=8700,
	["Tob Tobi Tobi"]=8500,["Te Te Te Sahur"]=9500,
	["Rhino Helicopterino"]=11000,["Magi Ribbitini"]=11500,
	["Tracoducotulu Delapeladustuz"]=12000,["Jingle Jingle Sahur"]=12200,
	["Los Noobinis"]=12500,["Cachorrito Melonito"]=13000,["Carloo"]=13500,
	["Elefanto Frigo"]=14000,["Carrotini Brainini"]=15000,
	["Centrucci Nuclucci"]=15500,["Jacko Spaventosa"]=16200,
	["Toiletto Focaccino"]=16000,["Bananito Bandito"]=16500,
	["Tree Tree Tree Sahur"]=17000,["Cocofanto Elefanto"]=17500,
	["Antonio"]=18500,["Girafa Celestre"]=20000,
	["Gattatino Neonino"]=35000,["Gattatino Nyanino"]=35000,
	["Chihuanini Taconini"]=45000,["Matteo"]=50000,
	["Tralalero Tralala"]=50000,["Los Crocodillitos"]=55000,
	["Tigroligre Frutonni"]=60000,["Espresso Signora"]=70000,
	["Odin Din Din Dun"]=75000,["Statutino Libertino"]=75000,
	["Tipi Topi Taco"]=75000,["Alessio"]=85000,
	["Tralalita Tralala"]=100000,["Tukanno Bananno"]=100000,
	["Orcalero Orcala"]=100000,["Extinct Ballerina"]=125000,
	["Trenostruzzo Turbo 3000"]=150000,["Urubini Flamenguini"]=150000,
	["Capi Taco"]=155000,["Gattito Tacoto"]=160000,
	["Trippi Troppi Troppa Trippa"]=175000,["Ballerino Lololo"]=200000,
	["Bulbito Bandito Traktorito"]=205000,["Los Tungtungtungcitos"]=210000,
	["Ballerina Peppermintina"]=215000,["Pakrahmatmamat"]=215000,
	["Los Bombinitos"]=220000,["Bombardini Tortinii"]=225000,
	["Piccione Macchina"]=225000,["Brr es Teh Patipum"]=225000,
	["Tractoro Dinosauro"]=230000,["Los Orcalitos"]=235000,
	["Corn Corn Corn Sahur"]=250000,["Squalanana"]=250000,
	["Dug Dug Dug"]=255000,["Yeti Claus"]=257500,["Ginger Globo"]=257500,
	["Los Tipi Tacos"]=260000,["Frio Ninja"]=265000,
	["Ginger Cisterna"]=293500,["Pop Pop Sahur"]=295000,
	["La Vacca Saturno Saturnita"]=300000,["Los Matteos"]=300000,
	["Bisonte Giuppitere"]=300000,["Jackorilla"]=315000,
	["Sammyni Spyderini"]=325000,["Chimpanzini Spiderini"]=325000,
	["Torrtuginni Dragonfrutini"]=350000,["Unclito Samito"]=350000,
	["Dul Dul Dul"]=375000,["Blackhole Goat"]=400000,["Chachechi"]=400000,
	["Guerriro Digitale"]=425000,["Agarrini la Palini"]=425000,
	["Extinct Tralalero"]=450000,["Fragola La La La"]=450000,
	["Los Spyderinis"]=450000,["La Cucaracha"]=475000,["Los Tortus"]=500000,
	["Los Tralaleritos"]=750000,["Extinct Matteo"]=500000,
	["Vulturino Skeletono"]=500000,["Boatito Auratito"]=525000,
	["Karkerkar Kurkur"]=550000,["Orcalita Orcala"]=575000,
	["Piccionetta Macchina"]=600000,["Las Tralaleritas"]=650000,
	["Job Job Job Sahur"]=700000,["Las Vaquitas Saturnitas"]=750000,
	["Los Combinasionas"]=800000,["Trenzostruzzo Turbo 4000"]=850000,
	["La Grande Combinasion"]=10000000,["Graipuss Medussi"]=1000000,
	["Anpali Babel"]=1200000,["Mastodontico Telepiedone"]=1200000,
	["Noo My Hotspot"]=1500000,["La Sahur Combinasion"]=2000000,
	["Nooo My Hotspot"]=2000000,["La Karkerkar Combinasion"]=17500000,
	["Pot Hotspot"]=2500000,["Esok Sekolah"]=3000000,
	["Chicleteira Bicicleteira"]=3500000,["67"]=7500000,
	["Los Nooo My Hotspotsitos"]=5500000,["Nuclearo Dinossauro"]=15000000,
	["Las Sis"]=17500000,["Celularcini Viciosini"]=22500000,
	["Los Bros"]=24000000,["Tralaledon"]=27500000,
	["La Esok Sekolah"]=30000000,["Tang Tang Kelentang"]=33500000,
	["Ketupat Kepat"]=35000000,["Tictac Sahur"]=37500000,
	["La Secret Combinasion"]=125000000,["Ketchuru and Musturu"]=42500000,
	["Garama and Madundung"]=50000000,["Spaghetti Tualetti"]=60000000,
	["Los Orcaleritos"]=235000000,["Dragon Cannelloni"]=200000000,
	["Strawberry Elephant"]=350000000,
}

-- ================================================================
--  MUTATION MULTIPLIERS  (additive: Lava 8 + Candy 4 = 12x total)
-- ================================================================
local MUTATION_MULTIPLIERS = {
	["Gold"]=1.25, ["Diamond"]=1.50, ["Rainbow"]=10.0,
	["Bloodrot"]=2.0, ["Candy"]=4.0, ["Lava"]=6.0,
	["Galaxy"]=7.0, ["Yin-Yang"]=7.5, ["Radioactive"]=8.5, ["Wet"]=1.5,
}

-- Additive sum so Lava(6) + Candy(4) = 10x, not 24x.
-- A brainrot with no mutations has 1x base; we add the mutation bonuses on top.
local function getTotalMultiplier(mutList)
	local bonus = 0
	for _, name in ipairs(mutList) do
		bonus = bonus + (MUTATION_MULTIPLIERS[name] or 0)
	end
	return 1 + bonus  -- base 1x + all stacked bonuses
end

-- ================================================================
--  REMOTE EVENTS
-- ================================================================
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

local function getOrCreate(name, class)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(class or "RemoteEvent")
		r.Name   = name
		r.Parent = Remotes
	end
	return r
end

local ConcentratorResult    = getOrCreate("ConcentratorResult")
local ConcentratorBroadcast = getOrCreate("ConcentratorBroadcast")
local ConcentratorInfo      = getOrCreate("ConcentratorInfo", "RemoteFunction")

-- ================================================================
--  DATASTORE
-- ================================================================
local discoveryStore = DataStoreService:GetDataStore(CONFIG.DS_DISCOVERIES)
local discoveryCache = {}

local function recipeKey(mutList)
	local s = table.clone(mutList)
	table.sort(s)
	return table.concat(s, "|")
end

local function checkDiscovery(mutList)
	local key = recipeKey(mutList)
	if discoveryCache[key] then
		return true, discoveryCache[key].discoverer, discoveryCache[key].blendedName
	end
	local ok, data = pcall(discoveryStore.GetAsync, discoveryStore, key)
	if ok and data then
		discoveryCache[key] = data
		return true, data.discoverer, data.blendedName
	end
	return false, nil, nil
end

local function recordDiscovery(mutList, playerName, blendedName)
	local key  = recipeKey(mutList)
	local data = {
		discoverer  = playerName,
		depth       = #mutList,
		blendedName = blendedName,
		timestamp   = os.time(),
	}
	local ok, err = pcall(discoveryStore.SetAsync, discoveryStore, key, data)
	if ok then
		discoveryCache[key] = data
	else
		warn("? DataStore write failed for key " .. key .. ": " .. tostring(err))
	end
	return ok
end

local function calcDiscoveryBonus(depth)
	return math.floor(CONFIG.BASE_DISCOVERY_REWARD * (CONFIG.DEPTH_MULTIPLIER ^ (depth - 1)))
end

-- ================================================================
--  GEMINI — blend mutation names into a creative label
-- ================================================================
local GEMINI_URL
local blendCache = {}

local function buildGeminiURL()
	return string.format(
		"https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
		CONFIG.GEMINI_MODEL,
		CONFIG.GEMINI_API_KEY
	)
end

--  Whole-word boundary check using Lua's %f frontier pattern.
--  Prevents "Lava" matching inside "Lavender", "Candy" inside "Candescent", etc.
--  Returns true only when more than half the input mutations
--  have a word from their name appear as a standalone word in the output.
local function isLazyOutput(output, mutList)
	local lower = output:lower()
	local matchCount = 0

	for _, m in ipairs(mutList) do
		for word in m:gmatch("%a+") do
			if #word > 3 then
				-- %f[%a] = transition from non-alpha to alpha (word start)
				-- %f[%A] = transition from alpha to non-alpha (word end)
				if lower:match("%f[%a]" .. word:lower() .. "%f[%A]") then
					warn(string.format(
						"   [LazyCheck] Forbidden word '%s' (from '%s') found in '%s'",
						word, m, output
						))
					matchCount += 1
					break  -- one match per mutation is enough
				end
			end
		end
	end

	local threshold = math.floor(#mutList / 2)
	local lazy = matchCount > threshold
	if lazy then
		warn(string.format(
			"   [LazyCheck] REJECTED '%s' — %d/%d mutations matched (threshold >%d)",
			output, matchCount, #mutList, threshold
			))
	end
	return lazy
end

--  Single Gemini call.  Pass rejectedAnswer on retries so the model
--  can see exactly what it did wrong.
local function callGemini(basePrompt, rejectedAnswer)
	GEMINI_URL = GEMINI_URL or buildGeminiURL()

	local fullPrompt = basePrompt
	if rejectedAnswer then
		fullPrompt = basePrompt
			.. "\n\n?? Your previous answer was REJECTED because it contained one or more of the input words verbatim."
			.. "\nRejected answer: \"" .. rejectedAnswer .. "\""
			.. "\nYou MUST produce something completely different that shares NO words with the inputs."
	end

	local payload = HttpService:JSONEncode({
		systemInstruction = {
			parts = { {
				text = "You are a creative mutation name generator for a silly Italian meme game. "
					.. "Output ONLY the invented name — no explanation, no punctuation at the end, nothing else. "
					.. "Never use the input words or their direct translations in any language."
			} }
		},
		contents = { { parts = { { text = fullPrompt } } } },
		generationConfig = { maxOutputTokens = 30, temperature = 1.1 },
	})

	local httpOk, raw = pcall(
		HttpService.PostAsync, HttpService,
		GEMINI_URL, payload, Enum.HttpContentType.ApplicationJson, false
	)

	if not httpOk then
		warn("?? Gemini HTTP error: " .. tostring(raw))
		return nil
	end

	-- Always log the raw response so failures are diagnosable in the output window
	print("   [Gemini RAW] " .. tostring(raw):sub(1, 500))

	local parseOk, parsed = pcall(HttpService.JSONDecode, HttpService, raw)

	if not parseOk or not parsed then
		warn("?? Gemini JSON parse failed")
		return nil
	end

	-- Surface API-level errors (e.g. invalid key, quota exceeded)
	if parsed.error then
		warn(string.format("?? Gemini API error %s: %s",
			tostring(parsed.error.code), tostring(parsed.error.message)))
		return nil
	end

	local cand = parsed.candidates and parsed.candidates[1]
	if not cand then
		warn("?? Gemini returned no candidates")
		-- Log promptFeedback if present (e.g. safety block)
		if parsed.promptFeedback then
			warn("   promptFeedback: " .. HttpService:JSONEncode(parsed.promptFeedback))
		end
		return nil
	end

	-- Log finish reason for any non-STOP result
	if cand.finishReason and cand.finishReason ~= "STOP" then
		warn("?? Gemini finishReason: " .. tostring(cand.finishReason))
	end

	local part = cand.content and cand.content.parts and cand.content.parts[1]
	if not part then
		warn("?? Gemini candidate has no content parts")
		return nil
	end

	local text = (part.text or ""):gsub("[\n\r]", ""):match("^%s*(.-)%s*$")
	if not text or text == "" then
		warn("?? Gemini returned empty text")
		return nil
	end

	return text
end

local function blendMutationNames(mutList)
	local key = recipeKey(mutList)
	if blendCache[key] then return blendCache[key] end

	-- Single mutation — no blending needed
	if #mutList == 1 then
		blendCache[key] = mutList[1]
		return mutList[1]
	end

	local listed = table.concat(mutList, " + ")

	local prompt = string.format(
		[[Fuse these mutation concepts into ONE invented name: %s

Rules:
- 1 to 4 words. Italian or Latin phonetics are encouraged where natural.
- Must feel like a brand-new standalone mutation name — evocative, not a description.
- You are completely banned from using any input words or their direct translations.

Good fusion examples:
"Lava" + "Radioactive"           ? "Toxic Inferno"
"Gold" + "Rainbow"               ? "Gilded Prism"
"Galaxy" + "Wet"                 ? "Nebula Tide"
"Bloodrot" + "Candy" + "Lava"    ? "Sugared Hellfire"
"Diamond" + "Yin-Yang"           ? "Crystallo Equilibrio"
"Radioactive" + "Wet"            ? "Irradiated Torrente"
"Galaxy" + "Yin-Yang" + "Wet"    ? "Cosmic Tidal Balance"]],
		listed
	)

	local MAX_ATTEMPTS = 3
	local result       = nil
	local lastBad      = nil

	for attempt = 1, MAX_ATTEMPTS do
		print(string.format("   [Gemini] Attempt %d/3 for [%s]", attempt, listed))

		local output = callGemini(prompt, attempt > 1 and lastBad or nil)

		if output then
			if isLazyOutput(output, mutList) then
				warn(string.format(
					"?? Gemini attempt %d rejected (lazy): '%s'", attempt, output
					))
				lastBad = output
				task.wait(0.5)
			else
				result = output
				print(string.format(
					"? Gemini blended [%s] ? '%s' (attempt %d)", listed, result, attempt
					))
				break
			end
		else
			warn("?? Gemini attempt " .. attempt .. " returned nil — check RAW log above")
			task.wait(0.5)
		end
	end

	-- Fallback: depth-flavoured Italian phrase that doesn't expose raw mutation names
	if not result then
		warn("?? All Gemini attempts exhausted for [" .. listed .. "] — using fallback")
		local depthLabel = ({
			[2] = "Duplice",
			[3] = "Triplice",
			[4] = "Quadruplice",
			[5] = "Quintuplice",
		})[#mutList] or "Multiplo"
		result = depthLabel .. " Fusione"
	end

	blendCache[key] = result
	return result
end

-- ================================================================
--  MUTATION ATTRIBUTE HELPERS
-- ================================================================
local function getMutations(tool)
	local raw = tool:GetAttribute("Mutations") or ""
	if raw == "" then
		local legacy = tool:GetAttribute("Mutation") or ""
		if legacy ~= "" then return { legacy } end
		return {}
	end
	local list = {}
	for m in raw:gmatch("[^,]+") do
		list[#list + 1] = m:match("^%s*(.-)%s*$")
	end
	return list
end

local function saveMutations(tool, mutList)
	tool:SetAttribute("Mutations", table.concat(mutList, ","))
end

-- ================================================================
--  VISUAL HELPERS
-- ================================================================
local ANIM_PRIORITY = {
	"Rainbow","Radioactive","Galaxy","Yin-Yang",
	"Lava","Candy","Wet","Bloodrot","Diamond","Gold",
}

local STATIC_VISUAL = {
	["Gold"]     = { col = Color3.fromRGB(255,215,0),   mat = Enum.Material.SmoothPlastic, ref = nil },
	["Diamond"]  = { col = Color3.fromRGB(185,242,255), mat = Enum.Material.SmoothPlastic, ref = 0.3 },
	["Bloodrot"] = { col = Color3.fromRGB(100,0,0),     mat = Enum.Material.SmoothPlastic, ref = nil },
	["Candy"]    = { col = Color3.fromRGB(255,105,180), mat = Enum.Material.SmoothPlastic, ref = 0.1 },
	["Lava"]     = { col = Color3.fromRGB(255,80,0),    mat = Enum.Material.Neon,          ref = nil },
	["Wet"]      = { col = Color3.fromRGB(84,130,255),  mat = Enum.Material.Neon,          ref = nil },
}

local LABEL_COLORS = {
	["Gold"]        = Color3.fromRGB(255,215,0),
	["Diamond"]     = Color3.fromRGB(185,242,255),
	["Bloodrot"]    = Color3.fromRGB(100,0,0),
	["Candy"]       = Color3.fromRGB(255,105,180),
	["Lava"]        = Color3.fromRGB(255,80,0),
	["Galaxy"]      = Color3.fromRGB(138,43,226),
	["Radioactive"] = Color3.fromRGB(0,255,50),
	["Wet"]         = Color3.fromRGB(84,130,255),
}

local function inList(val, list)
	for _, v in ipairs(list) do if v == val then return true end end
	return false
end

local function stripAppearances(model)
	for _, d in pairs(model:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("MeshPart") then
			local sa = d:FindFirstChildOfClass("SurfaceAppearance")
			if sa then sa:Destroy() end
		elseif d:IsA("SpecialMesh") then
			d.TextureId = ""
		end
	end
end

local function applyStackedVisuals(model, mutList)
	stripAppearances(model)

	local parts = {}
	for _, d in pairs(model:GetDescendants()) do
		if d:IsA("BasePart") then parts[#parts + 1] = d end
	end

	local chosen = nil
	for _, anim in ipairs(ANIM_PRIORITY) do
		if inList(anim, mutList) then chosen = anim; break end
	end

	if chosen == "Rainbow" then
		task.spawn(function()
			local hue = 0
			while model and model.Parent do
				hue = (hue + 0.01) % 1
				local c = Color3.fromHSV(hue, 1, 1)
				for _, p in ipairs(parts) do if p and p.Parent then p.Color = c end end
				task.wait(0.05)
			end
		end)

	elseif chosen == "Radioactive" then
		task.spawn(function()
			local t = 0
			while model and model.Parent do
				t += 0.08
				local g = math.floor(150 + 105 * (0.5 + 0.5 * math.sin(t)))
				local c = Color3.fromRGB(0, g, 0)
				for _, p in ipairs(parts) do
					if p and p.Parent then p.Color = c; p.Material = Enum.Material.Neon end
				end
				task.wait(0.05)
			end
		end)

	elseif chosen == "Galaxy" then
		task.spawn(function()
			local t = 0
			while model and model.Parent do
				t += 0.02
				local b = 0.5 + 0.5 * math.sin(t)
				local c = Color3.fromRGB(math.floor(75 + 63 * b), 0, math.floor(130 + 100 * b))
				for _, p in ipairs(parts) do
					if p and p.Parent then p.Color = c; p.Material = Enum.Material.Neon end
				end
				task.wait(0.05)
			end
		end)

	elseif chosen == "Yin-Yang" then
		task.spawn(function()
			local flip = false
			while model and model.Parent do
				flip = not flip
				local c = flip and Color3.new(1,1,1) or Color3.new(0,0,0)
				for _, p in ipairs(parts) do if p and p.Parent then p.Color = c end end
				task.wait(0.5)
			end
		end)

	else
		local v = chosen and STATIC_VISUAL[chosen]
		if v then
			for _, p in ipairs(parts) do
				if p and p.Parent then
					p.Color    = v.col
					p.Material = v.mat
					if v.ref then p.Reflectance = v.ref end
				end
			end
		end
	end
end

-- ================================================================
--  BILLBOARD UPDATE
-- ================================================================
local function animateRainbowLabel(lbl)
	task.spawn(function()
		local hue = 0
		while lbl and lbl.Parent do
			hue = (hue + 0.01) % 1
			lbl.TextColor3 = Color3.fromHSV(hue, 1, 1)
			task.wait(0.05)
		end
	end)
end

local function updateMutationBillboard(brainrotModel, blendedLabel, mutList)
	local statsGUI = brainrotModel:FindFirstChild("StatsGUI")
	if not statsGUI then return end

	local old = statsGUI:FindFirstChild("MutationLabel")
	if old then old:Destroy() end

	local labelColor = Color3.new(1,1,1)
	local doRainbow  = false
	local doYinYang  = false

	for _, anim in ipairs(ANIM_PRIORITY) do
		if inList(anim, mutList) then
			if   anim == "Rainbow"  then doRainbow = true
			elseif anim == "Yin-Yang" then doYinYang = true
			else
				local c = LABEL_COLORS[anim]
				if c then labelColor = c end
			end
			break
		end
	end

	local lbl = Instance.new("TextLabel")
	lbl.Name                   = "MutationLabel"
	lbl.Size                   = UDim2.new(1, 0, 0.2, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font                   = Enum.Font.SourceSansBold
	lbl.TextScaled             = true
	lbl.Text                   = "? " .. blendedLabel .. " ?"
	lbl.TextColor3             = labelColor
	lbl.TextStrokeColor3       = Color3.new(0,0,0)
	lbl.TextStrokeTransparency = 0
	lbl.LayoutOrder            = 2

	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = 35
	c.MinTextSize = 2
	c.Parent      = lbl

	lbl.Parent = statsGUI

	if doRainbow then
		animateRainbowLabel(lbl)
	elseif doYinYang then
		task.spawn(function()
			local flip = false
			while lbl and lbl.Parent do
				flip = not flip
				lbl.TextColor3 = flip and Color3.new(1,1,1) or Color3.new(0,0,0)
				task.wait(0.5)
			end
		end)
	end
end

-- ================================================================
--  CONCENTRATOR MODEL
-- ================================================================
local concentratorModel = workspace:FindFirstChild(CONFIG.CONCENTRATOR_MODEL_NAME, true)
if not concentratorModel then
	warn("?? WeatherConcentrator model not found in Workspace! System inactive.")
	warn("   Make sure a Model named '" .. CONFIG.CONCENTRATOR_MODEL_NAME .. "' exists in Workspace.")
	return
end
print("? Found concentrator model: " .. concentratorModel:GetFullName())

local pedestal = concentratorModel.PrimaryPart
if not pedestal then
	pedestal = concentratorModel:FindFirstChildWhichIsA("BasePart", true)
	if pedestal then
		warn("?? WeatherConcentrator has no PrimaryPart set — falling back to '"
			.. pedestal.Name .. "'. Set PrimaryPart in Studio for best results.")
	else
		warn("?? WeatherConcentrator has no BasePart at all! System inactive.")
		return
	end
end
print("? Using pedestal part: " .. pedestal:GetFullName())

local pedesLight = pedestal:FindFirstChildOfClass("PointLight")
if not pedesLight then
	pedesLight = Instance.new("PointLight")
	pedesLight.Brightness = 5
	pedesLight.Range      = 20
	pedesLight.Parent     = pedestal
end

local function refreshConcentratorGlow()
	local data = WeatherSystem.WEATHER_TYPES[WeatherSystem.getCurrentWeather()]
	local col  = (data and data.color) or Color3.fromRGB(200, 200, 255)
	TweenService:Create(pedesLight, TweenInfo.new(1.5), { Color = col }):Play()
	TweenService:Create(pedestal,   TweenInfo.new(1.5), { Color = col }):Play()
end
refreshConcentratorGlow()

task.spawn(function()
	while pedestal and pedestal.Parent do
		TweenService:Create(pedesLight,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Brightness = 8 }):Play()
		task.wait(1)
		TweenService:Create(pedesLight,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Brightness = 3 }):Play()
		task.wait(1)
	end
end)

-- ================================================================
--  PLAYER COOLDOWN
-- ================================================================
local cooldownMap = {}

local function isOnCooldown(player)
	local last = cooldownMap[player.UserId] or 0
	return (tick() - last) < CONFIG.PLAYER_COOLDOWN
end

local function getCooldownRemaining(player)
	local last = cooldownMap[player.UserId] or 0
	return math.max(0, math.ceil(CONFIG.PLAYER_COOLDOWN - (tick() - last)))
end

-- ================================================================
--  MAIN CRAFT FUNCTION
-- ================================================================
local function tryConcentrate(player)
	-- 1. Cooldown -------------------------------------------------
	if isOnCooldown(player) then
		ConcentratorResult:FireClient(player, false,
			"? Wait " .. getCooldownRemaining(player) .. "s before using again.", nil)
		return
	end

	-- 2. Active weather mutation -----------------------------------
	local currentWeather  = WeatherSystem.getCurrentWeather()
	local weatherData     = WeatherSystem.WEATHER_TYPES[currentWeather]
	local activeMutation  = weatherData and weatherData.mutation

	print(string.format("??? [Concentrator] %s triggered | weather: %s | mutation: %s",
		player.Name, tostring(currentWeather), tostring(activeMutation)))

	if currentWeather == "Clear" or not activeMutation then
		ConcentratorResult:FireClient(player, false,
			"?? No weather event active! Wait for a storm.", nil)
		return
	end

	-- 3. Player has a brainrot equipped ---------------------------
	local character = player.Character
	if not character then
		ConcentratorResult:FireClient(player, false, "? No character found.", nil)
		return
	end

	local tool = character:FindFirstChildOfClass("Tool")
	local pack = ReplicatedStorage:FindFirstChild("Brainrot pack1")

	if not tool or not pack then
		ConcentratorResult:FireClient(player, false, "?? Equip a Brainrot first!", nil)
		return
	end

	local validBrainrot = false
	for _, item in pairs(pack:GetChildren()) do
		if item.Name == tool.Name then validBrainrot = true; break end
	end
	if not validBrainrot then
		ConcentratorResult:FireClient(player, false,
			"?? Equip a valid Brainrot from your inventory!", nil)
		return
	end

	-- 4. Duplicate mutation guard ----------------------------------
	local currentMutations = getMutations(tool)
	for _, m in ipairs(currentMutations) do
		if m == activeMutation then
			ConcentratorResult:FireClient(player, false,
				"?? This brainrot already has the " .. activeMutation .. " mutation!", nil)
			return
		end
	end

	-- 5. Cost calculation ------------------------------------------
	local baseIncome = BRAINROT_INCOME[tool.Name] or 1
	local cost       = math.max(CONFIG.MIN_COST, baseIncome * CONFIG.COST_SECONDS)

	local leaderstats = player:FindFirstChild("leaderstats")
	local moneyValue  =
		(leaderstats and leaderstats.Parent:FindFirstChild("MoneyRaw")) or
		(leaderstats and leaderstats:FindFirstChild("Cash"))             or
		(leaderstats and leaderstats:FindFirstChild("Coins"))

	if not moneyValue then
		ConcentratorResult:FireClient(player, false,
			"? Money stat not found — contact an admin.", nil)
		return
	end

	if moneyValue.Value < cost then
		ConcentratorResult:FireClient(player, false,
			string.format("?? Need $%d (you have $%d).", cost, moneyValue.Value), nil)
		return
	end

	-- 6. Stamp cooldown immediately to prevent double-fire ---------
	cooldownMap[player.UserId] = tick()

	-- 7. Deduct cost -----------------------------------------------
	moneyValue.Value -= cost

	-- 8. All remaining work is async (Gemini + DataStore) ----------
	task.spawn(function()
		local newMutations = table.clone(currentMutations)
		table.insert(newMutations, activeMutation)

		-- Reuse stored name for known combos; only call Gemini for new ones
		local alreadyFound, _, storedName = checkDiscovery(newMutations)

		local blendedLabel
		if alreadyFound and storedName and storedName ~= "" then
			blendedLabel = storedName
			blendCache[recipeKey(newMutations)] = storedName
			print(string.format("?? Reused stored name [%s] ? '%s'",
				table.concat(newMutations, "+"), blendedLabel))
		else
			blendedLabel = blendMutationNames(newMutations)
		end

		-- Persist onto tool
		saveMutations(tool, newMutations)
		tool:SetAttribute("Mutation",     blendedLabel)
		tool:SetAttribute("MutationMult", getTotalMultiplier(newMutations))

		-- Update visuals
		applyStackedVisuals(tool, newMutations)
		updateMutationBillboard(tool, blendedLabel, newMutations)

		-- Record first discovery
		local discoveryBonus = nil
		if not alreadyFound then
			local depth    = #newMutations
			discoveryBonus = calcDiscoveryBonus(depth)
			recordDiscovery(newMutations, player.Name, blendedLabel)
			moneyValue.Value += discoveryBonus

			ConcentratorBroadcast:FireAllClients(
				player.Name,
				blendedLabel,
				tool.Name,
				discoveryBonus,
				depth
			)

			print(string.format(
				"?? FIRST DISCOVERY: '%s' by %s  depth=%d  bonus=$%d",
				blendedLabel, player.Name, depth, discoveryBonus
				))
		end

		-- Fire result to crafter
		local totalMult = getTotalMultiplier(newMutations)
		local msg
		if discoveryBonus then
			msg = string.format(
				"?? FIRST DISCOVERY! '%s' — You earned $%s bonus!",
				blendedLabel, string.format("%d", discoveryBonus)
			)
		else
			msg = string.format(
				"? Fused! Mutation is now: '%s'  (%.2fx income total)",
				blendedLabel, totalMult
			)
		end

		ConcentratorResult:FireClient(player, true, msg, discoveryBonus)

		-- Flash the pedestal
		task.spawn(function()
			for _ = 1, 5 do
				TweenService:Create(pedesLight, TweenInfo.new(0.1), { Brightness = 15 }):Play()
				task.wait(0.15)
				TweenService:Create(pedesLight, TweenInfo.new(0.1), { Brightness = 5 }):Play()
				task.wait(0.15)
			end
		end)

		print(string.format(
			"? %s | %s | fused: %s | cost: $%d | mult: %.2fx | depth: %d",
			player.Name, tool.Name, table.concat(newMutations, "+"),
			cost, totalMult, #newMutations
			))
	end)
end

-- ================================================================
--  PROXIMITY PROMPT
-- ================================================================
local prompt = concentratorModel:FindFirstChildWhichIsA("ProximityPrompt", true)
if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.ActionText            = "Concentrate"
	prompt.HoldDuration          = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent                = pedestal
	print("?? Auto-created ProximityPrompt on " .. pedestal:GetFullName())
else
	print("? Found existing ProximityPrompt: " .. prompt:GetFullName())
end

local function refreshPromptLabel()
	local weather = WeatherSystem.getCurrentWeather()
	local data    = WeatherSystem.WEATHER_TYPES[weather]
	if weather == "Clear" or not (data and data.mutation) then
		prompt.ObjectText = "Weather Concentrator  (waiting for storm…)"
	else
		prompt.ObjectText = string.format("Weather Concentrator  [%s]", data.mutation)
	end
end
refreshPromptLabel()

prompt.Triggered:Connect(function(player)
	tryConcentrate(player)
end)

-- ================================================================
--  REMOTE FUNCTION  — client cost preview
-- ================================================================
ConcentratorInfo.OnServerInvoke = function(player)
	local weather  = WeatherSystem.getCurrentWeather()
	local data     = WeatherSystem.WEATHER_TYPES[weather]
	local mutation = data and data.mutation
	local char     = player.Character
	local tool     = char and char:FindFirstChildOfClass("Tool")
	local base     = (tool and BRAINROT_INCOME[tool.Name]) or 0
	local cost     = math.max(CONFIG.MIN_COST, base * CONFIG.COST_SECONDS)
	local mutList  = tool and getMutations(tool) or {}
	local preview  = table.clone(mutList)
	if mutation then table.insert(preview, mutation) end
	return {
		cost           = cost,
		activeMutation = mutation,
		weatherDisplay = (data and data.displayName) or "Clear",
		previewMult    = getTotalMultiplier(preview),
		currentDepth   = #mutList,
		discoveryBonus = calcDiscoveryBonus(#preview),
	}
end

-- ================================================================
--  WEATHER CHANGE WATCHER
-- ================================================================
task.spawn(function()
	local last = WeatherSystem.getCurrentWeather()
	while true do
		task.wait(2)
		local cur = WeatherSystem.getCurrentWeather()
		if cur ~= last then
			last = cur
			refreshPromptLabel()
			refreshConcentratorGlow()
		end
	end
end)

-- ================================================================
--  CLEANUP
-- ================================================================
Players.PlayerRemoving:Connect(function(p)
	cooldownMap[p.UserId] = nil
end)

print("? WeatherConcentratorSystem loaded!")

print("   Concentrator: " .. concentratorModel:GetFullName())
