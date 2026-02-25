--=============================================================================
--Efficient compression algorithm--
--=============================================================================
--Uses this directory:
--////////////////////////////
--m = Model
--P = Part
--M = MeshPart
-- F = Folder
--G = ScreenGui / BillboardGui / SurfaceGui
--B = ImageButton / TextButton / TextBox
--p = ProximityPrompt
--S = Script
--L = LocalScript
--M = ModuleScript
--///////////////////////////////////
--The following rule exists for repetitive directories:
--If something is repeated more than 3 times i.e. model-model-model-part-script
--3mp|ScriptName
--//////////////////////////////////
--you will also need the ps1 script
--Figure it out if you use macbook
--ps1 script on discord
--//This script is fire//
local HttpService = game:GetService("HttpService")

-- Root service tokens
local ROOT_TOKENS = {
	Workspace = "w",
	ServerScriptService = "e",
	ReplicatedStorage = "r",
	StarterGui = "g",
	StarterPlayerScripts = "s",
	StarterCharacterScripts = "c"
}

-- Class tokens
local CLASS_TOKENS = {
	Model = "m",
	Part = "P",
	MeshPart = "M",
	Folder = "F",
	ScreenGui = "G",
	BillboardGui = "G",
	SurfaceGui = "G",
	ImageButton = "B",
	TextButton = "B",
	TextBox = "B",
	ProximityPrompt = "p"
}

-- Script type tokens
local SCRIPT_TYPE_TOKENS = {
	Script = "S",
	LocalScript = "L",
	ModuleScript = "M"
}

local function encodePath(obj)
	local segments = {}
	local current = obj.Parent

	while current and current ~= game do
		table.insert(segments, 1, current)
		current = current.Parent
	end

	local encoded = {}
	local i = 1

	while i <= #segments do
		local segment = segments[i]
		local className = segment.ClassName

		local token = ROOT_TOKENS[className] or CLASS_TOKENS[className]

		if token then
			local count = 1
			local j = i + 1

			while j <= #segments do
				local nextToken = ROOT_TOKENS[segments[j].ClassName] or CLASS_TOKENS[segments[j].ClassName]
				if nextToken == token then
					count += 1
					j += 1
				else
					break
				end
			end

			if count >= 3 then
				table.insert(encoded, tostring(count) .. token)
			elseif count == 2 then
				table.insert(encoded, token .. token)
			else
				table.insert(encoded, token)
			end

			i = j
		else
			-- Unknown class ? skip (keeps system compact)
			i += 1
		end
	end

	return table.concat(encoded)
end

local function exportOptimized()
	local exportDate = os.date("%Y-%m-%d_%H-%M")
	local finalContent = "EXPORT:" .. exportDate .. "\n"

	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("LuaSourceContainer") then
			local pathCode = encodePath(obj)
			local scriptType = SCRIPT_TYPE_TOKENS[obj.ClassName] or "?"
			local header = pathCode .. "|" .. scriptType .. "|" .. obj.Name

			finalContent ..= header .. "\n"
			finalContent ..= obj.Source .. "\n"
		end
	end

	print("Sending structurally encoded bundle...")
	local success, result = pcall(function()
		return HttpService:PostAsync(
			"http://127.0.0.1:8080/export",
			finalContent,
			Enum.HttpContentType.TextPlain
		)
	end)

	if success then
		print("Export complete.")
	else
		warn("Export failed: " .. result)
	end
end

exportOptimized()
