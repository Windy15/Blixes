--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local GameEnums = require(ReplicatedStorage.GameEnums)
local RandUtils = require(ReplicatedStorage.Modules.General.RandUtils)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)

local player = Players.LocalPlayer
local ProjectileRender = require(player.PlayerScripts.RenderHandlers.ProjectileRender)

local ToolClass = require(ReplicatedStorage.ToolClasses.ToolClass)

local Gun = setmetatable({
	ToolType = "Gun"
}, ToolClass)
Gun.__index = Gun

function Gun.new(config)
	local new = setmetatable(ToolClass.new(config), Gun)

	new.FiringModes = config.FiringModes or {GameEnums.GunMode.Semi}

	new.ShootType = config.ShootType or GameEnums.ShootType.Projectile

	if not config.ShootType then
		new.CurrentProjectile = {
			Name = "Bullet",
			Caster = FastCast.new(),
			HitConnection = nil
		}
	end

	new._ProjectileIds = {}

	for name in pairs(new.Projectiles) do
		new._ProjectileIds[name] = {}
	end

	new.OnShot = Signal.new()
	new.OnReloading = Signal.new()
	new.OnModeChanged = Signal.new()

	return new
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

function Gun:Shoot(direction, castBehvaiour)
	local activeCast = self.CurrentProjectile.Caster:Fire(self.Instance.Muzzle.Position, direction, self.BulletVelocity, castBehvaiour)
	local projId = RandUtils.generateId()
	self._ProjectileIds.Bullet[activeCast] = projId

	ProjectileRender.createProjectile(projId, ReplicatedStorage.Projectiles[self.CurrentProjectile.Name])
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