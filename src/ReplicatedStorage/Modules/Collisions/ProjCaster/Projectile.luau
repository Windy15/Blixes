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
    local timeCreated = os.clock()
    local self = setmetatable({
        Caster = caster,
        TimeCreated = timeCreated,

        InitialOrigin = origin,
        TrajectoryList = {Origin = origin, StartTime = timeCreated, Next = nil},
        _TrajectoryStepped = false, -- If the current trajectory has been used

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
            StartTime = os.clock(),
            Next = self.TrajectoryList,
        }
    end
    self.Velocity = velocity
end

function Projectile:ApplyImpulse(velocity: Vector3)
    self:ChangeVelocity(self.Velocity + velocity)
end

function Projectile:GetPivot()
    return CFrame.new(self.Position) * self.Rotation
end

function Projectile:GetFirstTrajectory()
    local traj = self.TrajectoryList
    while traj.Next do
        traj = traj.Next
    end
    return traj
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

local function calculateVelocity(gravity: Vector3, position: Vector3, initPos: Vector3, time: number)
	return (-0.5 * gravity * time ^ 2 - initPos) / time
end

RunService.PreSimulation:Connect(function()
    for _, proj in GlobalProjectiles do
        local caster = proj.Caster

        local oldpos = proj.Position
        local currentTraj = proj.TrajectoryList

        local gravity, velocity, origin, startTime = caster.Gravity, proj.Velocity, currentTraj.Origin, currentTraj.StartTime

        --desync
        local hit = caster:CalculateHit(proj)
        local newpos = calculatePosition(gravity, velocity, origin, os.clock() - startTime)
        --sync

        if hit then
            caster.OnProjHit:Fire(proj, hit)
            if caster.DestroyOnHit then
                proj:Destroy()
                continue
            end
        end

        proj.LastPosition = oldpos
        proj.Position = newpos

        proj._TrajectoryStepped = true
        caster.OnProjMoved:Fire(proj, newpos)
    end
end)

return Projectile