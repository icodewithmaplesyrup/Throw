local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ??? Developer check
local function isDeveloper(p)
	if RunService:IsStudio() then return true end
	return p.UserId == game.CreatorId or p.UserId == 10378926133 or p.UserId == 8834525880
end

if not isDeveloper(player) then return end

-- ---------------------------------------------
-- ??? Register your debug panels here
-- ---------------------------------------------
local DEBUG_PANELS = {
	{ guiName = "WeatherDebugUI",  frameName = "WeatherFrame",  label = "?? Weather"  },
	{ guiName = "DebugUI", frameName = "Frame",  label = "?? Brainrot" },
	{ guiName = "MainUI", frameName = "Panel", label = "?? Random"},
	{guiName = "DevMoneyButton", frameName = "Frame", label = "?? Money"},
	{guiName = "AdminFly", frameName = "Frame", label = "?? Fly"}
}

-- ---------------------------------------------
-- Build the container UI from scratch
-- ---------------------------------------------
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DebugContainerUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = PlayerGui

-- Outer frame
local frame = Instance.new("Frame")
frame.Name = "ContainerFrame"
frame.Size = UDim2.new(0, 200, 0, 40) -- starts minimized, expands below
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 6)
frameCorner.Parent = frame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "?? Debug Panel"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -34, 0, 3)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 16
minimizeBtn.Text = "-"
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeBtn

-- Panel list (vertical, below title bar)
local panelList = Instance.new("Frame")
panelList.Name = "PanelList"
panelList.Position = UDim2.new(0, 0, 0, 36)
panelList.Size = UDim2.new(1, 0, 0, 0) -- height driven by AutomaticSize
panelList.AutomaticSize = Enum.AutomaticSize.Y
panelList.BackgroundTransparency = 1
panelList.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = panelList

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 6)
listPadding.PaddingRight = UDim.new(0, 6)
listPadding.Parent = panelList

-- Auto-resize outer frame to fit list
local function updateFrameHeight()
	frame.Size = UDim2.new(0, 200, 0, 36 + panelList.AbsoluteSize.Y)
end
panelList:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateFrameHeight)

-- ---------------------------------------------
-- Register panels
-- ---------------------------------------------
for _, panel in ipairs(DEBUG_PANELS) do
	local debugGui = PlayerGui:WaitForChild(panel.guiName, 10)
	if not debugGui then
		warn("? DebugContainer: Could not find '" .. panel.guiName .. "'")
		continue
	end
	local debugFrame = debugGui:WaitForChild(panel.frameName, 10)
	if not debugFrame then
		warn("? DebugContainer: Could not find frame '" .. panel.frameName .. "'")
		continue
	end

	debugFrame.Visible = false

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
	btn.TextColor3 = Color3.fromRGB(220, 220, 255)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 13
	btn.Text = panel.label .. "  ?" -- ? = hidden
	btn.Parent = panelList

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = btn

	print("? DebugContainer: Registered '" .. panel.label .. "'")

	btn.MouseButton1Click:Connect(function()
		debugFrame.Visible = not debugFrame.Visible
		btn.Text = panel.label .. (debugFrame.Visible and "  ?" or "  ?")
		print("?? Toggled", panel.label, "?", debugFrame.Visible)
	end)
end

-- ---------------------------------------------
-- Minimize / expand
-- ---------------------------------------------
local expanded = true

minimizeBtn.MouseButton1Click:Connect(function()
	expanded = not expanded
	panelList.Visible = expanded
	minimizeBtn.Text = expanded and "-" or "+"
	if expanded then
		updateFrameHeight()
	else
		frame.Size = UDim2.new(0, 200, 0, 36)
	end
end)

-- ---------------------------------------------
-- Draggable
-- ---------------------------------------------
local dragging, dragStart, startPos

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

titleBar.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)