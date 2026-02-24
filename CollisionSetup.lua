-- CollisionGroupsSetup
-- Place in ServerScriptService
-- Must run BEFORE all other scripts that spawn or tag objects
-- Script order tip: prefix the name with "1_" e.g. "1_CollisionGroupsSetup"

local PhysicsService = game:GetService("PhysicsService")

print("?? Setting up collision groups...")

-- Register collision groups using the modern API
local groups = {"NPCs", "Environment", "Projectiles", "Players"}

for _, groupName in ipairs(groups) do
	if not PhysicsService:IsCollisionGroupRegistered(groupName) then
		PhysicsService:RegisterCollisionGroup(groupName)
		print("? Registered collision group: " .. groupName)
	else
		print("?? Collision group already registered: " .. groupName)
	end
end

-- Collision rules
-- NPCs (Brainrots) don't collide with Environment (trees, rocks, buildings)
PhysicsService:CollisionGroupSetCollidable("NPCs", "Environment", false)

-- NPCs don't collide with each other (prevents crowding and pushing)
PhysicsService:CollisionGroupSetCollidable("NPCs", "NPCs", false)

-- Projectiles collide with NPCs (can hit brainrots)
PhysicsService:CollisionGroupSetCollidable("Projectiles", "NPCs", true)

-- Projectiles pass through Environment (don't get blocked by trees, etc.)
PhysicsService:CollisionGroupSetCollidable("Projectiles", "Environment", false)

-- Projectiles pass through Players (don't hit the thrower)
PhysicsService:CollisionGroupSetCollidable("Projectiles", "Players", false)

-- Environment blocks Players (can't walk through trees, buildings, rocks)
PhysicsService:CollisionGroupSetCollidable("Environment", "Players", true)

-- NPCs walk through Players (brainrots don't push you around)
PhysicsService:CollisionGroupSetCollidable("NPCs", "Players", false)

print("? Collision groups configured!")
print("   NPCs    ? walk through Environment & Players")
print("   Projectiles ? hit NPCs, pass through Environment & Players")
print("   Players ? collide with Environment only")