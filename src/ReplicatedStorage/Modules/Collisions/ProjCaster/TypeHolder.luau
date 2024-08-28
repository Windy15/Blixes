--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local TypeHolder = {}

export type CalculateHit = (self: ProjCaster, proj: Projectile) -> RaycastResult?

export type ProjConfig = {
    RayParams: RaycastParams?,
    DestroyOnHit: boolean,

    Gravity: Vector3?,

    CalculateHit: CalculateHit?,

    UserData: {[string]: any}?,
}

export type ProjCasterImpl = {
    __index: ProjCasterImpl,
    __type: string,

    new: (config: ProjConfig) -> ProjCaster,
    Fire: (self: ProjCaster, origin: Vector3, velocity: Vector3) -> Projectile,
}

export type ProjCaster = typeof(setmetatable({} :: {
    RayParams: RaycastParams,
    DestroyOnHit: boolean,

    Gravity: Vector3,

    CalculateHit: CalculateHit,

    UserData: {[string]: any},

    OnProjHit: Signal.Signal<Projectile, RaycastResult>,
    OnProjCreated: Signal.Signal<Projectile>,
    OnProjMoved: Signal.Signal<Projectile, Vector3>,
    OnProjDestroyed: Signal.Signal<Projectile>,
}, {} :: ProjCasterImpl))

export type ProjectileImpl = {
    __index: ProjectileImpl,
    __type: string,

    new: (caster: ProjCaster, origin: Vector3, velocity: Vector3) -> Projectile,
    buffToId: (buff: buffer) -> number,
    idToBuff: (id: number) -> buffer,

    ChangeVelocity: (self: Projectile, velocity: Vector3) -> (),
    ApplyImpulse: (self: Projectile, velocity: Vector3) -> (),
    Destroy: (self: Projectile) -> (),
}

export type Trajectory = {
    Origin: Vector3,
    Next: Trajectory?,
}

export type Projectile = typeof(setmetatable({} :: {
    Id: number,
    Caster: ProjCaster,
    TimeFired: number,

    Origin: Vector3,
    TrajectoryList: Trajectory,
    _TrajectoryStepped: boolean, -- If the current trajectory has been used
    Velocity: Vector3,
    Position: Vector3,
    LastPosition: Vector3,
    Rotation: CFrame,
}, {} :: ProjectileImpl))

return TypeHolder