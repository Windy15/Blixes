--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local ToolClass = require(ReplicatedStorage.Tools.Classes.ToolClass)

local GunState = GameEnums.GunState

local Gun = {
	ToolType = "Gun"
}

local function defaultShoot(self, origin: Vector3, direction: Vector3)
	if not self.GunState:IsState(GunState.Idle) then return end
	self.GunState:SetState(GunState.Shooting)
	self.Shooter:Fire(origin, direction)
	self.Cleaner:AddObject(task.delay(self.FireRate, function()
		self.GunState:SetState(GunState.Idle)
	end))
end

local function defaultReload(self)
	if not self.GunState:IsState(GunState.Idle) then return end
	self.GunState:SetState(GunState.Reloading)

	self.Animations.ReloadAnimation:Play()

	self.Cleaner:AddObject(task.delay(self.ReloadTime, function()
		self.GunState:SetState(GunState.Idle)
	end))
end

function Gun.new(config)
	local self = ToolClass.new(config)

	self.FiringMode = EnumState.fromIds(self.FiringMode) -- It will be sent as a buffer and decoded on client
	self.GunState = self.GunState or EnumState.new(table.unpack(GunState.OrderedItems))

	self.Actions.Shoot = defaultShoot
	self.Actions.Reload = defaultReload

	self.OnShot = self.Cleaner:AddObject(Signal.new())
	self.OnReloading = self.Cleaner:AddObject(Signal.new())

	return self
end

return Gun