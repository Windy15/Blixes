local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ListClass = require(ReplicatedStorage.Modules.General.ListClass)

local VisualEffects = Players.LocalPlayer.PlayerScripts.VisualEffects
local ProjectileRemotes = ReplicatedStorage.Remotes.Projectiles

local CreateProjectile = ProjectileRemotes.CreateProjectile
local UpdatePosition = ProjectileRemotes.UpdatePosition
local RemoveProjectile = ProjectileRemotes.RemoveProjectile

local RenderFunctions = {}
local ProjectileRenders = ListClass.new({}, RenderFunctions)

function RenderFunctions.createProjectile(activeCastid, projectileFolder)
    local render = projectileFolder.Render:Clone()
    ProjectileRenders[activeCastid] = render

    local visualEffect = VisualEffects:FindFirstChild(projectileFolder.Name)
    if visualEffect then
        visualEffect.applyEffect(render)
    end
end

function RenderFunctions.updatePosition(activeCastid, cframe)
    local render =  ProjectileRenders[activeCastid]
    if not render then return end
    render:SetPivot(cframe)
end

function RenderFunctions.removeProjectile(activeCastid)
    if ProjectileRenders[activeCastid] then
        ProjectileRenders[activeCastid] = nil
    end
end

CreateProjectile.OnClientEvent:Connect(RenderFunctions.createProjectile) -- Create projectile client side
UpdatePosition.OnClientEvent:Connect(RenderFunctions.updatePosition) -- Replicate movement of projectile
RemoveProjectile.OnClientEvent:Connect(RenderFunctions.removeProjectile) -- Destroy projectile

return ProjectileRenders