--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)

local ToolClass = require(ReplicatedStorage.Tools.Classes.ToolClass)

local Gun = setmetatable({
	ToolType = "Gun"
}, ToolClass)
Gun.__index = Gun

function Gun.new(config)
	local self = setmetatable(ToolClass.new(config), Gun)

	self.FiringModes = config.FiringModes or {GameEnums.GunMode.Semi}

	self.OnShot = Signal.new()
	self.OnReloading = Signal.new()
	self.OnModeChanged = Signal.new()

	return self
end

--[[
function Gun:_ConfigBullets()
	for name, projectile in pairs(self.Projectiles) do
		local caster = projectile.Caster

		local projIds = {}
		self._ProjectileIds[name] = projIds

		caster.LengthChanged:Connect(function(activeCast, lastPoint, rayDir, displacement, segmentVelocity)
			local id = projIds[activeCast]
			if not id then return end
			ProjectileRender.updatePosition(id, CFrame.lookAt(lastPoint, rayDir))
		end)

		caster.CastTerminating:Connect(function(activeCast)
			ProjectileRender.removeProjectile(player, projIds[activeCast])
		end)
	end
end
]]

function Gun:Init()
	ToolClass.Init(self)
end

function Gun:Reload()
	if self.GunState ~= GameEnums.GunState.Idle then return end
	self.GunState = GameEnums.GunState.Reloading

	local reloadAnim = self.Player.Character:LoadAnimation(self.Instance.Animations.ReloadAnimation)
	reloadAnim:Play()

	task.delay(self.ReloadTime, function()
		self.GunState = GameEnums.GunState.Idle
	end)
end

function Gun:SetAiming(aiming)
	self.Aiming = aiming
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

	local ToolRemotes = self.Instance.Remotes
	ToolRemotes.ChangeMode:FireServer(mode)

	return mode
end

function Gun:ChangeMode(firingMode)
	local index = table.find(self.FiringModes, firingMode)
	if index then
		return self:SetCurrentMode(index)
	end
	return false
end

function Gun:NextMode()
	local nextIndex = self.CurrentMode % #self.FiringModes + 1
	self:ChangeMode(nextIndex)
end

return Gun