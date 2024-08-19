local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local Types = {}

type ShootComponentImpl = {
    __index: ShootComponentImpl,

    new: (holder: any) -> ShootComponent,
    Fire: (self: ShootComponent, origin: Vector3, direction: Vector3) -> ()
}

export type ShootComponent = typeof(setmetatable({} ::{
    Holder: any,

    OnFired: Signal.Signal<nil>,
    OnHit: Signal.Signal<RaycastResult>,
}, {} :: ShootComponentImpl))

return Types