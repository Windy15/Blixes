--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartCache = require(ReplicatedStorage.Modules.Parts.PartCache)
local Projectile = require(ReplicatedStorage.Modules.Collisions.ProjCaster.Projectile)

local ProjectileRemotes = ReplicatedStorage.Remotes.Projectiles

local CreateProjectile = ProjectileRemotes.CreateProjectile
local UpdatePosition = ProjectileRemotes.UpdatePosition
local RemoveProjectile = ProjectileRemotes.RemoveProjectile

export type Render = {
    Model: Model
}

local ProjectileRender = {
    Renders = table.create(1000) :: {[number]: Render}
}

function ProjectileRender.createProjectile(projId: buffer, projectileFolder)
    local id = Projectile.buffToId(projId)

    local render = projectileFolder.Render
    local model = PartCache[render] and PartCache[render]:GetPart() or render:Clone()

    ProjectileRender.Renders[id] = {
        Model = model,
    }

    local visualEffect = projectileFolder:FindFirstChild("VisualEffect")
    if visualEffect then
        visualEffect.applyEffect(model)
    end
end

function ProjectileRender.updatePosition(projId: buffer, cframe: CFrame)
    local id = Projectile.buffToId(projId)
    local render =  ProjectileRender.Renders[id]
    if not render then return end

    render.Model:PivotTo(cframe)
end

function ProjectileRender.removeProjectile(projId: buffer)
    local id = Projectile.buffToId(projId)
    local render = ProjectileRender.Renders[id]
    if render then
        render.Model:Destroy()
        ProjectileRender.Renders[id] = nil
    end
end

CreateProjectile.OnClientEvent:Connect(ProjectileRender.createProjectile) -- Create projectile client side
do
    local lastPacket = 0

    UpdatePosition.OnClientEvent:Connect(function(timeSent: number, ...)
        if timeSent < lastPacket then return end
        lastPacket = timeSent

        ProjectileRender.updatePosition(...)
    end)
end
UpdatePosition.OnClientEvent:Connect(ProjectileRender.updatePosition) -- Replicate movement of projectile
RemoveProjectile.OnClientEvent:Connect(ProjectileRender.removeProjectile) -- Destroy projectile

return ProjectileRender