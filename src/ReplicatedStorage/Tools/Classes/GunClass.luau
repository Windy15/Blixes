--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local ToolClass = require(ReplicatedStorage.Tools.Classes.ToolClass)

local Gun = setmetatable({
	ToolType = "Gun"
}, ToolClass)
Gun.__index = Gun

function Gun.new(config)
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
	if self.GunState:GetState() ~= GameEnums.GunState.Idle then return end
	self.GunState:SetState(GameEnums.GunState.Reloading)

	local reloadAnim = self.Player.Character:LoadAnimation(self.Instance.Animations.ReloadAnimation)
	reloadAnim:Play()

	task.delay(self.ReloadTime, function()
		self.GunState:SetState(GameEnums.GunState.Idle)
	end)
end

function Gun:SetAiming(aiming)
	self.Aiming = aiming
end

return Gun