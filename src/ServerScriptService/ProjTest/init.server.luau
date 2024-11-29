--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjCaster = require(ReplicatedStorage.Modules.Physics.ProjCaster)

local radius = 1

local gun = ProjCaster.new({
	Gravity = -Vector3.yAxis,
	Radius = radius
})

local rng = Random.new()

local function randDir()
	return Vector3.xAxis * rng:NextNumber(0, 10) + Vector3.zAxis * rng:NextNumber(0, 10)
end

local iter = 1000

local projs = table.create(iter)

gun.OnProjCreated:Connect(function(proj)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * radius
	part.Transparency = 0.5
	part.Material = Enum.Material.Neon
	part.Position = proj.Position
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.FrontSurface = Enum.SurfaceType.Hinge
	part.Parent = workspace

	projs[proj.Id] = part
end)

gun.OnProjMoved:Connect(function(proj)
	local part = projs[proj.Id]
	if part then
		part.CFrame = CFrame.new(proj.Position, proj.Position + proj.Caster.Gravity + proj.Velocity)
	end
end)

gun.OnProjHit:Connect(function(proj, result)
	local part = projs[proj.Id]
	if part then
		part.Color = Color3.new(1, 0, 0)
	end

	local normal = proj.Velocity.Unit
	local newVelocity = (normal - (2 * normal:Dot(result.Normal) * result.Normal)) * proj.Velocity.Magnitude
	proj:ChangeVelocity(newVelocity)
end)

gun.OnProjDestroyed:Connect(function(proj)
	local part = projs[proj.Id]
	if part then
		part:Destroy()
	end
end)

task.wait(3)

for _ = 1, iter do
	gun:Fire(Vector3.yAxis * 20, randDir())
end