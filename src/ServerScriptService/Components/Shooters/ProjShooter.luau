--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local Types = require(ServerScriptService.Components.Types)
local ProjTypes = require(ReplicatedStorage.Modules.Collisions.ProjCaster.TypeHolder)
local Projectile = require(ReplicatedStorage.Modules.Collisions.ProjCaster.Projectile)

local CreateProjectileRemote = ReplicatedStorage.Remotes.Projectiles.CreateProjectile
local UpdatePositionRemote = ReplicatedStorage.Remotes.Projectiles.UpdatePosition
local RemoveProjectileRemote = ReplicatedStorage.Remotes.Projectiles.RemoveProjectile

type ProjShooterImpl = {
    __index: ProjShooterImpl,

    new: (holder: Types.Holder, caster: ProjTypes.ProjCaster, visualsFolder: Folder?, replicateBlacklist: {Player}?) -> ProjShooter,
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
            CreateProjectileRemote:FireAllClients(Projectile.idToBuff(proj.Id), visualsFolder)
        end
        self.OnFired:Fire({
            Projectile = proj
        })
    end)

    if visualsFolder then
        caster.OnProjMoved:Connect(function(proj)
            local timeCreated = os.clock()
            for _, player in Players:GetPlayers() do
                if player ~= holder.Player then
                    UpdatePositionRemote:FireClient(player, timeCreated, Projectile.idToBuff(proj.Id), proj:GetPivot())
                end
            end
        end)
    end

    caster.OnProjHit:Connect(function(proj, result)
        self.OnHit:Fire(result, {
            Projectile = proj
        })
    end)

    if visualsFolder then
        caster.OnProjDestroyed:Connect(function(proj)
            RemoveProjectileRemote:FireAllClients(Projectile.idToBuff(proj.Id))
        end)
    end

    return self
end

function ProjShooter:Fire(origin: Vector3, direction: Vector3)
    self.Caster:Fire(origin, direction)
end

return ProjShooter