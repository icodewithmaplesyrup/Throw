-- Shared number formatting module
-- Use this anywhere you need to format numbers with suffixes

local NumberFormat = {}

local suffixes = {
	"", "K", "M", "B", "T",
	"Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qd", "QiD",
	"SxD", "SpD", "OcD", "NoD"
}

function NumberFormat.format(num)
	-- Safety check just in case a nil value passes through
	if not num then return "0" end

	if num < 1000 then
		return tostring(math.floor(num))
	end

	local magnitude = math.floor(math.log10(num) / 3)

	-- [THE FIX]: Add +1 because Lua tables start at index 1!
	-- magnitude 1 (Thousands) + 1 = Index 2 ("K")
	local suffix = suffixes[magnitude + 1] or ("e" .. (magnitude * 3))

	local short = num / (1000 ^ magnitude)

	-- Format to 2 decimal places, then remove unnecessary ".00"
	-- This turns "10.00M" into "10M", while keeping "1.25M" intact
	local formatted = string.format("%.2f", short):gsub("%.?0+$", "")

	return formatted .. suffix
end

return NumberFormat