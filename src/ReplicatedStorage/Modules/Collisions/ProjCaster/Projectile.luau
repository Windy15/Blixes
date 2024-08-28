--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GenerationId = require(ReplicatedStorage.Modules.General.GenerationId)
local TypeHolder = require(script.Parent.TypeHolder)

local PROJ_INIT_SIZE = 1000

local ProjIdGen = GenerationId.new(PROJ_INIT_SIZE)
local GlobalProjectiles = table.create(PROJ_INIT_SIZE)

local Projectile = {} :: TypeHolder.ProjectileImpl
Projectile.__index = Projectile
Projectile.__type = "Projectile"

function Projectile.new(caster, origin, velocity)
    local self = setmetatable({
        Caster = caster,
        TimeFired = os.clock(),

        Origin = origin,
        TrajectoryList = {Origin = origin, Next = nil},
        _TrajectoryStepped = false,
        Velocity = velocity,
        Position = origin,
        LastPosition = origin,
        Rotation = CFrame.identity,
    }, Projectile)

    local id = ProjIdGen:CreateId(self)
    self.Id = id
    GlobalProjectiles[id] = self

    return self
end

function Projectile.buffToId(buff: buffer)
    return buffer.readu16(buff, 0)
end

function Projectile.idToBuff(id: number)
    local buff = buffer.create(2)
    buffer.writeu16(buff, 0, id)
    return buff
end

function Projectile:ChangeVelocity(velocity: Vector3)
    if self._TrajectoryStepped then
        self.TrajectoryList = {
            Origin = self.Position,
            Next = self.TrajectoryList,
        }
    end
    self.Velocity = velocity
end

function Projectile:ApplyImpulse(velocity: Vector3)
    self:ChangeVelocity(self.Velocity + velocity)
end

function Projectile:Destroy()
    if RunService:IsServer() then
        GlobalProjectiles[self.Id] = nil
        ProjIdGen:RemoveId(self)
    end

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
        proj.LastPosition = oldpos
        local newpos = calculatePosition(caster.Gravity, proj.Velocity, proj.TrajectoryList.Origin, os.clock() - proj.TimeFired)
        proj.Position = newpos

        proj._TrajectoryStepped = true
        caster.OnProjMoved:Fire(proj, newpos)
    end
end)

return Projectile