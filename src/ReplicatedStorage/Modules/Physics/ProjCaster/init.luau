--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Projectile = require(script.Projectile)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local TypeHolder = require(script.TypeHolder)

local ProjCaster = {} :: TypeHolder.ProjCasterImpl
ProjCaster.__index = ProjCaster
ProjCaster.__type = "ProjCaster"

local DEFAULT_RAY_PARAMS = RaycastParams.new()
DEFAULT_RAY_PARAMS.RespectCanCollide = true

function ProjCaster.new(config: TypeHolder.ProjConfig)
    return setmetatable({
        RayParams = config.RayParams or DEFAULT_RAY_PARAMS,
        DestroyOnHit = config.DestroyOnHit or false,

        Gravity = config.Gravity or -workspace.Gravity * Vector3.yAxis,
        Radius = config.Radius or 0,

        UserData = {},

        HitFuncName = config.HitFuncName or "Default",

        OnProjHit = Signal.new(),
        OnProjCreated = Signal.new(),
        OnProjMoved = Signal.new(),
        OnProjDestroyed = Signal.new()
    }, ProjCaster)
end

function ProjCaster:Fire(origin: Vector3, velocity: Vector3)
    local cast = Projectile.new(self, origin, velocity)
    self.OnProjCreated:Fire(cast)
    return cast
end

return ProjCaster