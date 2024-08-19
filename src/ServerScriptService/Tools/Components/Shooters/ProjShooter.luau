--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local Types = require(ServerScriptService.Tools.Components.Types)

type ProjShooterImpl = {
    __index: ProjShooterImpl,

    new: (holder: any, caster: any) -> ProjShooter,
    Fire: (self: ProjShooter, origin: Vector3, direction: Vector3) -> (),
}

export type ProjShooter = Types.ShootComponent & typeof(setmetatable({} :: {}, {} :: ProjShooterImpl))

local ProjShooter = {}
ProjShooter.__index = ProjShooter

function ProjShooter.new(holder, caster)
    return setmetatable({
        Holder = holder,
        Caster = caster,

        OnFired = Signal.new(),
        OnHit = Signal.new(),
    }, ProjShooter)
end

function ProjShooter:Fire(origin: Vector3, direction: Vector3)
    self.OnFired:Fire()

end

return ProjShooter