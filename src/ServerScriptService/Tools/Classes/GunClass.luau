--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Characters = require(ReplicatedStorage.Players.Characters)
local ComponentTypes = require(ServerScriptService.Components.Types)
local EnumList = require(ReplicatedStorage.Modules.General.EnumList)
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
	ToolType: string,

	new: (config: GunConfig) -> GunObject,
	_ConfigBullets: (self: GunObject) -> (),
	Init: (self: GunObject) -> (),
	Reload: (self: GunObject) -> (),
	GetMode: (self: GunObject) -> EnumList.EnumItem,
	SetCurrentMode: (self: GunObject, index: number) -> (),
	ChangeMode: (self: GunObject, firingMode: EnumList.EnumItem) -> (),
	GetReplicateConfig: (self: GunObject) -> {[any]: any}
}, {} :: ToolClass.ToolImpl))

export type GunConfig = ToolClass.ToolConfig & {
	DisplayName: string,

	Damage: number,
	FireRate: number,
	ReloadTime: number,

	Shooter: ComponentTypes.ShootComponent,

	FiringMode: EnumState.EnumState,

	_CreateDamageConnection: boolean?,
}

export type GunObject = ToolClass.ToolObject & GunConfig & typeof(setmetatable({} :: {
	GunState: EnumState.EnumState,

	OnShot: Signal.Signal<>,
	OnReloading: Signal.Signal<>,
}, setmetatable({}, {}) :: GunImpl))


function Gun.new(config): GunObject
	local self = setmetatable(ToolClass.new(config), Gun) :: GunObject

	self.GunState = self.GunState or EnumState.new(table.unpack(GunState.OrderedItems))

	self.OnShot = self.Cleaner:AddObject(Signal.new())
	self.OnReloading = self.Cleaner:AddObject(Signal.new())

	if self._CreateDamageConnection then
		self.Shooter.OnHit:Connect(function(result)
			local char = Characters:GetCharFromInstance(result.Instance)
			if char then
				char.Instance.Humanoid:TakeDamage(self.Damage)
			end
		end)
	end

	return self
end

function Gun:Init()
	ToolClass.Init(self)
end

function Gun:GetReplicateConfig()
	local config = ToolClass.GetReplicateConfig(self)
	config.FiringMode = EnumState.toIds(self.FiringMode)
	config.Damage = self.Damage
	config.FireRate = self.FireRate
	config.ReloadTime = self.ReloadTime
	return config
end

function Gun:Reload()
	if not self.GunState:IsState(GunState.Idle) then return end
	self.GunState:SetState(GunState.Reloading)

	self.Cleaner:AddObject(task.delay(self.ReloadTime, function()
		self.GunState:SetState(GunState.Idle)
	end))
end

return Gun