--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local TypeHolder = {}

export type CalculateHit = (self: ProjCaster, proj: Projectile) -> RaycastResult?

export type ProjConfig = {
    RayParams: RaycastParams?,
    DestroyOnHit: boolean?,

    Gravity: Vector3?,
    Radius: number?,
    Ricochet: boolean?,

    HitFuncName: string?,

    UserData: {[string]: any}?,
}

export type ProjCasterImpl = {
    __index: ProjCasterImpl,
    __type: "ProjCaster",

    new: (config: ProjConfig) -> ProjCaster,
    Fire: (self: ProjCaster, origin: Vector3, velocity: Vector3) -> Projectile,
}

export type ProjCaster = typeof(setmetatable({} :: {
    RayParams: RaycastParams,
    DestroyOnHit: boolean,

    Gravity: Vector3,
    Radius: number,

    HitFuncName: string,

    UserData: {[string]: any},

    OnProjHit: Signal.Signal<Projectile, RaycastResult>,
    OnProjCreated: Signal.Signal<Projectile>,
    OnProjMoved: Signal.Signal<Projectile, Vector3>,
    OnProjDestroyed: Signal.Signal<Projectile>,
}, {} :: ProjCasterImpl))

export type ProjectileImpl = {
    __index: ProjectileImpl,
    __type: "Projectile",

    new: (caster: ProjCaster, origin: Vector3, velocity: Vector3) -> Projectile,
    buffToId: (buff: buffer) -> number,
    idToBuff: (id: number) -> buffer,

    SetValue: (self: Projectile, key: string, value: any) -> (),
    UpdatePosition: (self: Projectile, pos: Vector3) -> (),
    ChangeVelocity: (self: Projectile, velocity: Vector3) -> (),
    ApplyImpulse: (self: Projectile, velocity: Vector3) -> (),
    GetPivot: (self: Projectile) -> CFrame,
    GetFirstTrajectory: (self: Projectile) -> Trajectory,
    Destroy: (self: Projectile) -> (),
}

export type Trajectory = {
    Origin: Vector3,
    InitVelocity: Vector3,
    StartTime: number,
    Next: Trajectory?,
}

export type Projectile = typeof(setmetatable({} :: {
    Id: number,
    Caster: ProjCaster,
    TimeCreated: number,

    InitialOrigin: Vector3,
    TrajectoryList: Trajectory,
    _TrajectoryStepped: boolean,

    Position: Vector3,
    LastPosition: Vector3,
    Velocity: Vector3,

    Rotation: CFrame,

    ExtraData: {[string]: any},

    _Actor: Actor?,
}, {} :: ProjectileImpl))

export type ProjData = {
	StartTime: number,
	Origin: Vector3,
	Position: Vector3,
	LastPosition: Vector3,
	InitVelocity: Vector3,
    Velocity: Vector3,
	Gravity: Vector3,

    Radius: number,
	RayParams: RaycastParams,
	HitCalc: (self: ProjData) -> RaycastResult?,
}

return TypeHolder