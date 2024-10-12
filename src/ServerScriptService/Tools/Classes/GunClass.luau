--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Characters = require(ServerScriptService.Players.Characters)
local ComponentTypes = require(ServerScriptService.Components.Types)
local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local ToolClass = require(ServerScriptService.Tools.Classes.ToolClass)

local GunState = GameEnums.GunState

local Gun = setmetatable({
	ToolType = "Gun",
}, ToolClass) :: GunImpl
Gun.__index = Gun

type GunImpl = typeof(setmetatable({} :: {
	__index: GunImpl,
	ToolType: "Gun",

	new: (config: GunConfig) -> GunObject,
	Init: (self: GunObject, config: InitConfig) -> (),
	Shoot: (self: GunObject, origin: Vector3, direction: Vector3) -> (),
	Reload: (self: GunObject) -> (),
	GetReplicateConfig: (self: GunObject) -> {[any]: any},
	Destroy: (self: GunObject) -> (),
}, {} :: ToolClass.ToolImpl))

export type GunConfig = ToolClass.ToolConfig & {
	DisplayName: string,

	Damage: number,
	FireRate: number,
	ReloadTime: number,

	FiringMode: EnumState.EnumState,
}

type InitConfig = {
	_CreateDamageConnection: boolean?
}

export type GunObject = ToolClass.ToolObject & GunConfig & typeof(setmetatable({} :: {
	GunState: EnumState.EnumState,

	Shooter: ComponentTypes.ShootComponent,

	OnShot: Signal.Signal<>,
	OnReloading: Signal.Signal<>,
}, setmetatable({}, {}) :: GunImpl))


function Gun.new(config): GunObject
	local self = setmetatable(ToolClass.new(config), Gun) :: GunObject

	self.GunState = self.GunState or EnumState.new(table.unpack(GunState.OrderedItems))

	self.OnShot = self.Cleaner:AddObject(Signal.new())
	self.OnReloading = self.Cleaner:AddObject(Signal.new())

	return self
end

function Gun:Init(config)
	ToolClass.Init(self, config)

	if config._CreateDamageConnection then
		self.Shooter.OnHit:Connect(function(result)
			local char = Characters:GetCharFromInstance(result.Instance)
			if char then
				char:TakeDamage(self.Damage)
			end
		end)
	end
end

function Gun:GetReplicateConfig()
	local config = ToolClass.GetReplicateConfig(self)
	config.FiringMode = EnumState.toIds(self.FiringMode)
	config.Damage = self.Damage
	config.FireRate = self.FireRate
	config.ReloadTime = self.ReloadTime
	return config
end

function Gun:Shoot(origin, direction)
	if not self.GunState:IsState(GunState.Idle) then return end
	self.GunState:SetState(GunState.Shooting)
	self.Shooter:Fire(origin, direction)
	self.Cleaner:AddObject(task.delay(self.FireRate, function()
		self.GunState:SetState(GunState.Idle)
	end))
end

function Gun:Reload()
	if not self.GunState:IsState(GunState.Idle) then return end
	self.GunState:SetState(GunState.Reloading)

	self.Cleaner:AddObject(task.delay(self.ReloadTime, function()
		self.GunState:SetState(GunState.Idle)
	end))
end

function Gun:Destroy()
	self.GunState:SetState(GunState.Idle)
	ToolClass.Destroy(self)
end

return Gun