-- Put this in ServerScriptService/EnvironmentSetup
-- This automatically assigns all parts in an "Environment" folder to the Environment collision group

local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")

-- Wait for Environment folder (create it if it doesn't exist)
local environmentFolder = Workspace:FindFirstChild("Environment")
if not environmentFolder then
	environmentFolder = Instance.new("Folder")
	environmentFolder.Name = "Environment"
	environmentFolder.Parent = Workspace
	print("?? Created Environment folder in Workspace")
end

-- Function to assign all parts in a model to Environment group
local function setupEnvironmentObject(object)
	if object:IsA("Model") or object:IsA("Folder") then
		for _, descendant in pairs(object:GetDescendants()) do
			if descendant:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(descendant, "Environment")
			end
		end
	elseif object:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(object, "Environment")
	end
end

-- Setup existing objects
for _, object in pairs(environmentFolder:GetChildren()) do
	setupEnvironmentObject(object)
	print("?? Setup environment object: " .. object.Name)
end

-- Watch for new objects added to Environment folder
environmentFolder.ChildAdded:Connect(function(object)
	task.wait(0.1) -- Wait for all descendants to load
	setupEnvironmentObject(object)
	print("?? New environment object added: " .. object.Name)
end)

print("? Environment Setup loaded!")
print("?? To add decorations:")
print("   1. Put trees, rocks, buildings in Workspace/Environment folder")
print("   2. They'll automatically be set to Environment collision group")
print("   3. Brainrots will walk through them, projectiles will too")