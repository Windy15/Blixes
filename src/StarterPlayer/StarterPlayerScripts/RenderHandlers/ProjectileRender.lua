local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes.Projectile

local UpdatePosition = Remotes.UpdatePosition
local RemoveProjectile = Remotes.RemoveProjectile

local ProjectileRenders = {}

UpdatePosition.OnClientEvent:Connect(function(activeCastid, folder, cframe) -- fire FastCast data to clients so they can mimic the hitbox's movements
    local render =  ProjectileRenders[activeCastid]

    if not render then
        render = folder.Render:Clone()
        ProjectileRenders[activeCastid] = render

        local visualEffect = folder:FindFirstChild("VisualEffect")

        if visualEffect then
            task.spawn(visualEffect, render)
        end
    end

    render:SetPivot(cframe)
end)

RemoveProjectile.OnClientEvent:Connect(function(id)
    if ProjectileRenders[id] then
        ProjectileRenders[id] = nil
    end
end)

return ProjectileRenders