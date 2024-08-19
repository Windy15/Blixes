--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EnumList = require(ReplicatedStorage.Modules.General.EnumList)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local Stat = require(ReplicatedStorage.Modules.General.Stat)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)
local ToolClass = require(ServerScriptService.Tools.Classes.ToolClass)

local Gun = setmetatable({
	ToolType = "Gun"
}, ToolClass)
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

type GunConfig = {
	Damage: Stat.Stat<number>,
	FireRate: Stat.Stat<number>,
	ReloadTime: Stat.Stat<number>,

	GunState: EnumList.EnumItem,
	FiringModes: {EnumList.EnumItem},
	CurrentMode: number,

	OnShot: Signal.Signal<nil>,
	OnReloading: Signal.Signal<nil>,
	OnModeChanged: Signal.Signal<nil>,
}
export type GunObject = typeof(setmetatable({} :: GunConfig & ToolClass.ToolObject, {} :: GunImpl))

function Gun.new(config): GunObject
	local self = setmetatable(ToolClass.new(config), Gun)
	self.Damage = Stat.new(config.Damage or 0)
	self.FireRate = Stat.new(config.FireRate or 1)
	self.ReloadTime = Stat.new(config.ReloadTime or 3)

	self.GunState = GameEnums.GunState.Idle
	self.FiringModes = config.FiringModes or {GameEnums.GunMode.Semi}
	self.CurrentMode = config.CurrentMode or 1

	self.OnShot = Signal.new()
	self.OnReloading = Signal.new()
	self.OnModeChanged = Signal.new()

	return self
end

function Gun:Init()
	ToolClass.Init(self)
end

function Gun:Reload()
	if self.Reloading then return end
	self.Reloading = true

	task.delay(self.ReloadTime.Value, function()
		self.Reloading = false
	end)
end

function Gun:GetMode()
	return self.FiringModes[self.CurrentMode]
end

function Gun:SetCurrentMode(index)
	local mode = self.FiringModes[index]
	if not self.FiringModes[index] then
		error(string.format("'%d' is not a valid index in FiringModes for %s", index, StringUtils.formatAddress(self, "Gun")), 2)
	end

	self.CurrentMode = index
	self.OnModeChanged:Fire(mode)

	return mode
end

function Gun:ChangeMode(firingMode)
	local index = table.find(self.FiringModes, firingMode)
	if index then
		return self:SetCurrentMode(index)
	end
	return false
end

return Gun