--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartCache = require(ReplicatedStorage.Modules.Parts.PartCache)

local ProjectileRemotes = ReplicatedStorage.Remotes.Projectiles

local CreateProjectile = ProjectileRemotes.CreateProjectile
local UpdatePosition = ProjectileRemotes.UpdatePosition
local RemoveProjectile = ProjectileRemotes.RemoveProjectile

local RenderFunctions = {}
RenderFunctions.__index = RenderFunctions
local ProjectileRenders = setmetatable({}, RenderFunctions)

function RenderFunctions.createProjectile(projId, projectileFolder)
    local render = projectileFolder.Render
    local model = PartCache[render] and PartCache[render]:GetPart() or render:Clone()

    ProjectileRenders[projId] = {
        Render = model,
    }

    local visualEffect = projectileFolder:FindFirstChild("VisualEffect")
    if visualEffect then
        visualEffect.applyEffect(model)
    end
end

function RenderFunctions.updatePosition(projId: string, cframe: CFrame)
    local render =  ProjectileRenders[projId]
    if not render then return end

    render.Render:SetPivot(cframe)
end

function RenderFunctions.removeProjectile(projId)
    local render = ProjectileRenders[projId]
    if render then
        render.Render:Destroy()
        ProjectileRenders[projId] = nil
    end
end

CreateProjectile.OnClientEvent:Connect(RenderFunctions.createProjectile) -- Create projectile client side
do
    local lastPacket = 0

    UpdatePosition.OnClientEvent:Connect(function(timeSent, ...)
        if timeSent < lastPacket then return end
        lastPacket = timeSent

        RenderFunctions.updatePosition(...)
    end)
end
UpdatePosition.OnClientEvent:Connect(RenderFunctions.updatePosition) -- Replicate movement of projectile
RemoveProjectile.OnClientEvent:Connect(RenderFunctions.removeProjectile) -- Destroy projectile

return ProjectileRenders