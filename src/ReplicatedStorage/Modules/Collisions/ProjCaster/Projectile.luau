--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GenerationId = require(ReplicatedStorage.Modules.General.GenerationId)
local TypeHolder = require(script.Parent.TypeHolder)

local PROJ_INIT_SIZE = 1000

local LocalIdGen = GenerationId.new(PROJ_INIT_SIZE) -- Id's for locally created projectiles (NOT FOR REPLICATION)
local GlobalProjectiles = table.create(PROJ_INIT_SIZE)

local Projectile = {} :: TypeHolder.ProjectileImpl
Projectile.__index = Projectile
Projectile.__type = "Projectile"

function Projectile.new(caster, origin, velocity)
    local self = setmetatable({
        Caster = caster,
        TimeFired = os.clock(),

        Origin = origin,
        TrajectoryOrigin = origin,
        Velocity = velocity,
        Position = origin,
    }, Projectile)
    local id = LocalIdGen:CreateId(self)
    self.LocalId = id
    GlobalProjectiles[id] = self
    return self
end

function Projectile:ChangeTrajectory(velocity: Vector3)
    self.TrajectoryOrigin = self.Position
    self.Velocity = velocity
end

function Projectile:ApplyImpulse(velocity: Vector3)
    self.TrajectoryOrigin = self.Position
    self.Velocity += velocity
end

function Projectile:Destroy()
    GlobalProjectiles[self.LocalId] = nil
    LocalIdGen:RemoveId(self)
    self.Caster.OnProjDestroyed:Fire(self)
end

local function calculatePosition(gravity: Vector3, velocity: Vector3, initPos: Vector3, time: number)
	return 0.5 * gravity * time ^ 2 + velocity * time + initPos
end

RunService.PreSimulation:Connect(function()
    for _, proj in GlobalProjectiles do
        local caster = proj.Caster

        local hit = caster:CalculateHit(proj)
        if hit then
            caster.OnProjHit:Fire(proj, hit)
            if caster.DestroyOnHit then
                proj:Destroy()
                continue
            end
        end

        local oldpos = proj.Position
        local newpos = calculatePosition(caster.Gravity, proj.Velocity, proj.TrajectoryOrigin, os.clock() - proj.TimeFired)
        proj.Position = newpos
        caster.OnProjMoved:Fire(proj, oldpos, newpos)
    end
end)

return Projectile