local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes.Projectile

local CreateProjectile = Remotes.CreateProjectile
local UpdatePosition = Remotes.UpdatePosition
local RemoveProjectile = Remotes.RemoveProjectile

local ProjectileRenders = {}

CreateProjectile.OnClientEvent:Connect(function(activeCastid, projectileFolder)
    ProjectileRenders[activeCastid] = projectileFolder.Render:Clone()

    local visualEffect = projectileFolder:FindFirstChild("VisualEffect")

    if visualEffect then
        task.spawn(visualEffect, projectileFolder)
    end
end)

UpdatePosition.OnClientEvent:Connect(function(activeCastid, cframe) -- fire FastCast data to clients so they can mimic the hitbox's movements
    local render =  ProjectileRenders[activeCastid]
    if not render then return end
    render:SetPivot(cframe)
end)

RemoveProjectile.OnClientEvent:Connect(function(id)
    if ProjectileRenders[id] then
        ProjectileRenders[id] = nil
    end
end)

return ProjectileRenders