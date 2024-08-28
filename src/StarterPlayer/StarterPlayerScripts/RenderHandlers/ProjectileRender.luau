--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartCache = require(ReplicatedStorage.Modules.Parts.PartCache)
local Projectile = require(ReplicatedStorage.Modules.Collisions.ProjCaster.Projectile)

local ProjectileRemotes = ReplicatedStorage.Remotes.Projectiles

local CreateProjectile = ProjectileRemotes.CreateProjectile
local UpdatePosition = ProjectileRemotes.UpdatePosition
local RemoveProjectile = ProjectileRemotes.RemoveProjectile

local RENDERS_INIT_SIZE = 1000

export type Render = {
    Model: Model
}

local ProjectileRender = {
    ReplicatedRenders = table.create(RENDERS_INIT_SIZE) :: {[number]: Render},
    ClientRenders = table.create(RENDERS_INIT_SIZE) :: {[number]: Render}
}

function ProjectileRender.createProjectile(projId: number, projectileFolder)
    local render = projectileFolder.Render
    local model = PartCache[render] and PartCache[render]:GetPart() or render:Clone()

    ProjectileRender.ClientRenders[projId] = {
        Model = model,
    }

    local visualEffect = projectileFolder:FindFirstChild("VisualEffect")
    if visualEffect then
        visualEffect.applyEffect(model)
    end
end

function ProjectileRender.updatePosition(projId: number, cframe: CFrame)
    local render =  ProjectileRender.ClientRenders[projId]
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
    local model = PartCache[render] and PartCache[render]:GetPart() or render:Clone()

    ProjectileRender.ReplicatedRenders[id] = {
        Model = model,
    }

    local visualEffect = projectileFolder:FindFirstChild("VisualEffect")
    if visualEffect then
        visualEffect.applyEffect(model)
    end
end)

local lastPacket = 0

UpdatePosition.OnClientEvent:Connect(function(timeSent: number, projId: buffer, cframe: CFrame)
    if timeSent < lastPacket then return end
    lastPacket = timeSent

    local id = Projectile.buffToId(projId)
    local render =  ProjectileRender.ReplicatedRenders[id]
    if not render then return end

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

return ProjectileRender