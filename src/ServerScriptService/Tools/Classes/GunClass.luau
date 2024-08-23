local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EnumList = require(ReplicatedStorage.Modules.General.EnumList)
local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local ToolClass = require(ServerScriptService.Tools.Classes.ToolClass)

local Gun = setmetatable({
	ToolType = "Gun"
}, ToolClass) :: GunImpl
Gun.__index = Gun

type GunImpl = {
	__index: GunImpl,
	ToolType: string,

	new: (config: GunConfig) -> GunObject,
	_ConfigBullets: (self: GunObject) -> (),
	Init: (self: GunObject) -> (),
	Reload: (self: GunObject) -> (),
	GetMode: (self: GunObject) -> EnumList.EnumItem,
	SetCurrentMode: (self: GunObject, index: number) -> (),
	ChangeMode: (self: GunObject, firingMode: EnumList.EnumItem) -> ()
}

export type GunConfig = ToolClass.ToolConfig & {
	Damage: number,
	FireRate: number,
	ReloadTime: number,

	FiringMode: EnumState.EnumState,

	OnShot: Signal.Signal<nil>,
	OnReloading: Signal.Signal<nil>,
	OnModeChanged: Signal.Signal<EnumList.EnumItem>,
}
export type GunObject = ToolClass.ToolObject & typeof(setmetatable({} :: GunConfig & {
	GunState: EnumList.EnumItem
}, {} :: GunImpl))

function Gun.new(config): GunObject
	local self = setmetatable(ToolClass.new(config), Gun)

	self.GunState = EnumState.new(table.unpack(GameEnums.GunState.OrderedItems))

	self.OnShot = Signal.new()
	self.OnReloading = Signal.new()
	self.OnModeChanged = Signal.new()

	return self
end

function Gun:Init()
	ToolClass.Init(self)
end

function Gun:Reload()
	if self.GunState:GetState() == GameEnums.GunState.Reloading then return end
	self.Reloading = true

	task.delay(self.ReloadTime, function()
		self.Reloading = false
	end)
end

return Gun