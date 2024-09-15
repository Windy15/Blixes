--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local Types = require(ServerScriptService.Components.Types)

type RayShooterImpl = {
    __index: RayShooterImpl,

    new: (holder: Types.Holder, rayParams: RaycastParams?, pierceLimit: number?, ricochetLimit: number?) -> RayShooter,
    Fire: (self: RayShooter, origin: Vector3, direction: Vector3) -> (),
}

export type RayShooter = Types.ShootComponent & typeof(setmetatable({} :: {
    RayParams: RaycastParams,
    PierceLimit: number,
    RicochetLimit: number,
}, {} :: RayShooterImpl))

local RayShooter = {} :: RayShooterImpl
RayShooter.__index = RayShooter

local DEFAULT_PARAMS = RaycastParams.new()

function RayShooter.new(holder, rayParams, pierceLimit, ricochetLimit)
    return setmetatable({
        Holder = holder,

        RayParams = rayParams or DEFAULT_PARAMS,
        PierceLimit = pierceLimit or 0,
        RicochetLimit = ricochetLimit or 0,

        OnFired = Signal.new(),
        OnHit = Signal.new(),
    }, RayShooter) :: RayShooter
end

function RayShooter:Fire(origin, direction)
    self.OnFired:Fire()
    local result = workspace:Raycast(origin, direction, self.RayParams)
    if result then
        self.OnHit:Fire(result)
    end
end

return RayShooter