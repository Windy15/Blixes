--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartCache = require(ReplicatedStorage.Modules.Parts.PartCache)
local Projectile = require(ReplicatedStorage.Modules.Collisions.ProjCaster.Projectile)
local Types = require(ReplicatedStorage.Modules.Collisions.ProjCaster.TypeHolder)

local ProjectileRemotes = ReplicatedStorage.Remotes.Projectiles

local CreateProjectile = ProjectileRemotes.CreateProjectile
local UpdatePosition = ProjectileRemotes.UpdatePosition
local RemoveProjectile = ProjectileRemotes.RemoveProjectile
local RecreateProjectile = ProjectileRemotes.RecreateProjectile

local RENDERS_INIT_SIZE = 1000

export type ClientRender = {
    Model: Model
}

export type ReplicatedRender = ClientRender & {
    LastPacket: number
}

local ProjectileRender = {
    ReplicatedRenders = table.create(RENDERS_INIT_SIZE) :: {[number]: ReplicatedRender},
    ClientRenders = table.create(RENDERS_INIT_SIZE) :: {[number]: ClientRender}
}

function ProjectileRender.createProjectile(projId: number, projectileFolder)
    local render = projectileFolder.Render
    local pool = PartCache:GetPool(render)
    local model = if pool then pool:GetPart() else render:Clone()

    ProjectileRender.ClientRenders[projId] = {
        Model = model,
    }

    local visualEffect = projectileFolder:FindFirstChild("VisualEffect")
    if visualEffect then
        visualEffect.applyCreated(model)
    end
end

function ProjectileRender.updatePosition(projId: number, cframe: CFrame)
    local render = ProjectileRender.ClientRenders[projId]
    if not render then return end

    render.Model:PivotTo(cframe)
end

function ProjectileRender.removeProjectile(projId: number)
    local render = ProjectileRender.ClientRenders[projId]
    if render then
        render.Model:Destroy()
        ProjectileRender.ClientRenders[projId] = nil
    end
end


CreateProjectile.OnClientEvent:Connect(function(projId: buffer, projectileFolder) -- Create projectile client side
    local id = Projectile.buffToId(projId)

    local render = projectileFolder.Render
    local pool = PartCache:GetPool(render)
    local model = if pool then pool:GetPart() else render:Clone()

    ProjectileRender.ReplicatedRenders[id] = {
        Model = model,
        LastPacket = 0,
    }

    local visualEffect = projectileFolder:FindFirstChild("VisualEffect")
    if visualEffect then
        visualEffect.applyCreated(model)
    end
end)

UpdatePosition.OnClientEvent:Connect(function(timeSent: number, projId: buffer, cframe: CFrame)
    local id = Projectile.buffToId(projId)
    local render =  ProjectileRender.ReplicatedRenders[id]
    if not render then return end

    if timeSent < render.LastPacket then return end
    render.LastPacket = timeSent

    render.Model:PivotTo(cframe)
end)

UpdatePosition.OnClientEvent:Connect(function(projId: buffer, cframe: CFrame) -- Replicate movement of projectile
    local id = Projectile.buffToId(projId)
    local render =  ProjectileRender.ReplicatedRenders[id]
    if not render then return end

    render.Model:PivotTo(cframe)
end)

RemoveProjectile.OnClientEvent:Connect(function(projId: buffer) -- Destroy projectile
    local id = Projectile.buffToId(projId)
    local render = ProjectileRender.ReplicatedRenders[id]
    if render then
        render.Model:Destroy()
        ProjectileRender.ReplicatedRenders[id] = nil
    end
end)

RecreateProjectile.OnClientEvent:Connect(function(origin: Vector3, velocity: Vector3, projectileFolder)
    local module = projectileFolder:FindFirstChild("Caster")
    assert(module, `ProjectileFolder {projectileFolder} has no Caster module`)
    local Caster = require(module) :: Types.ProjCaster
    Caster:Fire(origin, velocity)
end)

return ProjectileRender