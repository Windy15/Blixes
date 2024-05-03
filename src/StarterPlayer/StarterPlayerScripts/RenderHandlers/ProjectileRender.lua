local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ListClass = require(ReplicatedStorage.Modules.General.ListClass)
local PartCache = require(ReplicatedStorage.Modules.Parts.PartCache)

local VisualEffects = Players.LocalPlayer.PlayerScripts.VisualEffects
local ProjectileRemotes = ReplicatedStorage.Remotes.Projectiles

local CreateProjectile = ProjectileRemotes.CreateProjectile
local UpdatePosition = ProjectileRemotes.UpdatePosition
local RemoveProjectile = ProjectileRemotes.RemoveProjectile

local RenderFunctions = {}
local ProjectileRenders = ListClass.new({}, RenderFunctions)

function RenderFunctions.createProjectile(activeCastid, projectileFolder, hertz)
    local render = projectileFolder.Render
    local model = PartCache[render] and PartCache[render]:GetPart() or render:Clone()

    ProjectileRenders[activeCastid] = {
        Render = model,
        Hertz = hertz,
        LastLerp = 0,
        LerpConnection = nil
    }

    local visualEffect = VisualEffects:FindFirstChild(projectileFolder.Name)
    if visualEffect then
        visualEffect.applyEffect(model)
    end
end

local lastPacket = 0

function RenderFunctions.updatePosition(activeCastid, cframe, timeSent)
    if timeSent and timeSent < lastPacket then return end
    lastPacket = timeSent

    local render =  ProjectileRenders[activeCastid]
    if not render then return end

    if not render.Hertz then
        render.Render:SetPivot(cframe)
    else
        if render.LerpConnection then
            render.LerpConnection:Disconnect()
        end

        render.LerpConnection = RunService.Stepped:Connect(function(_, deltaTime)
            local newLerp = render.LastLerp + (render.Hertz * deltaTime)
            if newLerp >= 1 then
                render.LerpConnection:Disconnect()
            end
            local model = render.Render
            model.CFrame = model.CFrame:Lerp(cframe, math.clamp(newLerp, 0, 1))
            render.LastUpdated = os.clock()
            render.LastLerp = newLerp
        end)
    end
end

function RenderFunctions.removeProjectile(activeCastid)
    local render = ProjectileRenders[activeCastid]
    if render then
        render.Render:Destroy()
        ProjectileRenders[activeCastid] = nil
    end
end

CreateProjectile.OnClientEvent:Connect(RenderFunctions.createProjectile) -- Create projectile client side
UpdatePosition.OnClientEvent:Connect(RenderFunctions.updatePosition) -- Replicate movement of projectile
RemoveProjectile.OnClientEvent:Connect(RenderFunctions.removeProjectile) -- Destroy projectile

return ProjectileRenders