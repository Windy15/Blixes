--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local Types = require(ReplicatedStorage.Tools.Components.Types)
local ProjTypes = require(ReplicatedStorage.Modules.Collisions.ProjCaster.TypeHolder)

local ProjectileRender = require(Players.LocalPlayer.PlayerScripts.RenderHandlers.ProjectileRender)

type ProjShooterImpl = {
    __index: ProjShooterImpl,

    new: (holder: Types.Holder, caster: ProjTypes.ProjCaster, visualsFolder: Folder?) -> ProjShooter,
    Fire: (self: ProjShooter, origin: Vector3, direction: Vector3) -> (),
}

export type ProjShooter = Types.ShootComponent & typeof(setmetatable({} :: {
    Caster: ProjTypes.ProjCaster,
    VisualsFolder: Folder,
}, {} :: ProjShooterImpl))

local ProjShooter = {} :: ProjShooterImpl
ProjShooter.__index = ProjShooter

function ProjShooter.new(holder, caster, visualsFolder)
    local self = setmetatable({
        Holder = holder,
        Caster = caster,
        VisualsFolder = visualsFolder,

        OnFired = Signal.new(),
        OnHit = Signal.new(),
    }, ProjShooter) :: ProjShooter

    caster.OnProjCreated:Connect(function(proj)
        if visualsFolder then
            ProjectileRender.createProjectile(proj.Id, visualsFolder :: any)
        end
        self.OnFired:Fire({
            Projectile = proj
        })
    end)

    if visualsFolder then
        caster.OnProjMoved:Connect(function(proj)
            ProjectileRender.updatePosition(proj.Id, proj:GetPivot())
        end)
    end

    caster.OnProjHit:Connect(function(proj, result)
        self.OnHit:Fire(result, {
            Projectile = proj
        })
    end)

    if visualsFolder then
        caster.OnProjDestroyed:Connect(function(proj)
            ProjectileRender.removeProjectile(proj.Id)
        end)
    end

    return self
end

function ProjShooter:Fire(origin: Vector3, direction: Vector3)
    self.Caster:Fire(origin, direction)
end

return ProjShooter