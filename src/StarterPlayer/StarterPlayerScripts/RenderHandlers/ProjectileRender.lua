local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes.Projectile

local CreateProjectile = Remotes.CreateProjectile
local UpdatePosition = Remotes.UpdatePosition
local RemoveProjectile = Remotes.RemoveProjectile

local ProjectileRenders = {}

function ProjectileRenders.createProjectile(activeCastid, projectileFolder)
    ProjectileRenders[activeCastid] = projectileFolder.Render:Clone()

    local visualEffect = projectileFolder:FindFirstChild("VisualEffect")

    if visualEffect then
        task.spawn(visualEffect, projectileFolder)
    end
end

function ProjectileRenders.updatePosition(activeCastid, cframe)
    local render =  ProjectileRenders[activeCastid]
    if not render then return end
    render:SetPivot(cframe)
end

function ProjectileRenders.removeProjectile(activeCastid)
    if ProjectileRenders[activeCastid] then
        ProjectileRenders[activeCastid] = nil
    end
end

CreateProjectile.OnClientEvent:Connect(ProjectileRenders.createProjectile)
UpdatePosition.OnClientEvent:Connect(ProjectileRenders.updatePosition)-- fire FastCast data to clients so they can mimic the hitbox's movements
RemoveProjectile.OnClientEvent:Connect(ProjectileRenders.removeProjectile)

return ProjectileRenders