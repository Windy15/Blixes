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

local Gun = {
	ToolType = "Gun",
} :: GunImpl

type GunImpl = {
	ToolType: "Gun",

	new: (config: GunConfig, initConfig: InitConfig?) -> GunObject
}

export type GunConfig = ToolClass.ToolConfig & {
	Damage: number,
	FireRate: number,
	ReloadTime: number,

	FiringMode: EnumState.EnumState,
}

type InitConfig = {
	_CreateDamageConnection: boolean?
}

export type GunObject = ToolClass.ToolObject & GunConfig & {
	ToolCategory: GunImpl,
	GunState: EnumState.EnumState,

	Shooter: ComponentTypes.ShootComponent,
	Actions: {
		Shoot: (self: GunObject, origin: Vector3, direction: Vector3) -> (),
		Reload: (self: GunObject) -> (),
	},
	Cooldowns: {},

	OnShot: Signal.Signal<>,
	OnReloading: Signal.Signal<>,
}

local function defaultShoot(self: GunObject, origin: Vector3, direction: Vector3)
	if not self.GunState:IsState(GunState.Idle) then return end
	self.GunState:SetState(GunState.Shooting)
	self.Shooter:Fire(origin, direction)
	self.Cleaner:AddObject(task.delay(self.FireRate, function()
		self.GunState:SetState(GunState.Idle)
	end))
end

local function defaultReload(self: GunObject)
	if not self.GunState:IsState(GunState.Idle) then return end
	self.GunState:SetState(GunState.Reloading)

	self.Cleaner:AddObject(task.delay(self.ReloadTime, function()
		self.GunState:SetState(GunState.Idle)
	end))
end

function Gun.new(config, initConfig)
	local self = ToolClass.new(config) :: GunObject

	self.ToolCategory = Gun

	self.FiringMode = EnumState.new(table.unpack(GameEnums.FiringMode.OrderedItems))
	self.GunState = self.GunState or EnumState.new(table.unpack(GunState.OrderedItems))

	self.Actions.Shoot = defaultShoot
	self.Actions.Reload = defaultReload

	self.OnShot = self.Cleaner:AddObject(Signal.new())
	self.OnReloading = self.Cleaner:AddObject(Signal.new())

	if initConfig then
		self.OnInitialized:Connect(function()
			if initConfig._CreateDamageConnection then
				self.Shooter.OnHit:Connect(function(result)
					local char = Characters:GetCharFromInstance(result.Instance)
					if char then
						char:TakeDamage(self.Damage)
					end
				end)
			end
		end)
	end

	return self
end

return Gun