-- MutationHandler (ModuleScript) -- place in ReplicatedStorage
-- Central source of truth for mutation definitions, rolls, multipliers, colors,
-- weather gating, and optional model-pack overrides.

local MutationHandler = {}

MutationHandler.DEFAULT_MODEL_PACK = "Brainrot pack1"
MutationHandler.MODEL_PACKS = {
	Squashed = "Brainrot packSquashed",
}

MutationHandler.MUTATIONS = {
	Gold = {
		multiplier = 1.25,
		baseRate = 250,
		color = Color3.fromRGB(255, 215, 0),
		limited = false,
	},
	Diamond = {
		multiplier = 1.5,
		baseRate = 102,
		color = Color3.fromRGB(185, 242, 255),
		limited = false,
	},
	Rainbow = {
		multiplier = 10.0,
		baseRate = 5,
		color = "Rainbow",
		limited = false,
	},
	Bloodrot = {
		multiplier = 2.0,
		baseRate = 0,
		color = Color3.fromRGB(100, 0, 0),
		limited = true,
		weather = { "Bloodstorm" },
	},
	Candy = {
		multiplier = 4.0,
		baseRate = 0,
		color = Color3.fromRGB(255, 105, 180),
		limited = true,
		weather = { "Candyland" },
		modelPack = "Squashed", -- Example custom model pack override
	},
	Lava = {
		multiplier = 6.0,
		baseRate = 0,
		color = Color3.fromRGB(255, 80, 0),
		limited = true,
		weather = { "Volcanic" },
	},
	Galaxy = {
		multiplier = 7.0,
		baseRate = 0,
		color = Color3.fromRGB(138, 43, 226),
		limited = true,
		weather = { "Galactic" },
	},
	["Yin-Yang"] = {
		multiplier = 7.5,
		baseRate = 0,
		color = "YinYang",
		limited = true,
		weather = { "YinYang" },
	},
	Radioactive = {
		multiplier = 8.5,
		baseRate = 0,
		color = Color3.fromRGB(0, 255, 50),
		limited = true,
		weather = { "Radioactive" },
	},
	Wet = {
		multiplier = 1.5,
		baseRate = 0,
		color = Color3.fromRGB(84, 130, 255),
		limited = true,
		weather = { "Rain" },
	},
}

local PERMANENT_ROLL_ORDER = { "Rainbow", "Diamond", "Gold" }

function MutationHandler.getDefinition(mutationName)
	return MutationHandler.MUTATIONS[mutationName]
end

function MutationHandler.getMultiplier(mutationName)
	local def = MutationHandler.getDefinition(mutationName)
	return (def and def.multiplier) or 1
end

function MutationHandler.getColor(mutationName)
	local def = MutationHandler.getDefinition(mutationName)
	return def and def.color
end

function MutationHandler.rollPermanentMutation()
	local roll = math.random(1, 1000)
	local cumulative = 0
	for _, mutationName in ipairs(PERMANENT_ROLL_ORDER) do
		local def = MutationHandler.MUTATIONS[mutationName]
		cumulative += (def and def.baseRate or 0)
		if roll <= cumulative then
			return mutationName
		end
	end
	return nil
end

function MutationHandler.getModelPackNameForMutation(mutationName)
	local def = MutationHandler.getDefinition(mutationName)
	if not def or not def.modelPack then
		return MutationHandler.DEFAULT_MODEL_PACK
	end
	return MutationHandler.MODEL_PACKS[def.modelPack] or def.modelPack
end

function MutationHandler.resolveModelTemplate(replicatedStorage, baseModelName, mutationName)
	if not replicatedStorage or not baseModelName then return nil, nil end

	local defaultFolder = replicatedStorage:FindFirstChild(MutationHandler.DEFAULT_MODEL_PACK)
	if not defaultFolder then return nil, nil end

	local defaultTemplate = defaultFolder:FindFirstChild(baseModelName)
	if not mutationName then
		return defaultTemplate, defaultTemplate
	end

	local modelPackName = MutationHandler.getModelPackNameForMutation(mutationName)
	local mutationFolder = replicatedStorage:FindFirstChild(modelPackName)
	if mutationFolder then
		local mutatedTemplate = mutationFolder:FindFirstChild(baseModelName)
		if mutatedTemplate then
			return mutatedTemplate, defaultTemplate
		end
	end

	return defaultTemplate, defaultTemplate
end

return MutationHandler
