--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local Types = {}

export type Holder = {
    Player: Player
} | any

type ShootComponentImpl = {
    __index: ShootComponentImpl,

    new: (holder: Holder) -> ShootComponent,
    Fire: (self: ShootComponent, origin: Vector3, direction: Vector3) -> (),

    Destroy: (self: ShootComponent) -> (),
}

type ExtraData = {[string]: any}

export type ShootComponent = typeof(setmetatable({} ::{
    Holder: Holder,
    Replicating: boolean,

    OnFired: Signal.Signal<ExtraData?>,
    OnHit: Signal.Signal<RaycastResult, ExtraData?>,
}, {} :: ShootComponentImpl))

return Types