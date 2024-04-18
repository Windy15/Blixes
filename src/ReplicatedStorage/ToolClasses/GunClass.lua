local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)

local player = Players.LocalPlayer
local ProjectileRender = require(player.PlayerScripts.RenderHandlers.ProjectileRender)

local ToolClass = require(ReplicatedStorage.ToolClasses.ToolClass)

local Gun = {
	ToolType = "Gun"
}
Gun.__index = Gun

function Gun.new(config)
	local new = setmetatable(ToolClass.new(config), Gun)
	new.Damage = config.Damage or 0
	new.FireRate = config.Damage or 1
	new.ReloadTime = 3

	new.GunState = GameEnums.GunState.Idle
	new.FiringModes = config.FiringModes or {GameEnums.ToolState.Semi}
	new.CurrentMode = config.CurrentMode or 1

	new.BulletVelocity = config.BulletVelocity or 100
	new.Projectiles = config.Projectiles or {
		Bullet = {
			Caster = FastCast.new()
		}
	}
	new.CurrentProjectile = config.CurrentProjectile or "Bullet"
	new._ActiveCastIds = {}

	for name in pairs(new.Projectiles) do
		new._ActiveCastIds[name] = {}
	end

	new.OnShot = Signal.new()
	new.OnReloading = Signal.new()
	new.OnModeChanged = Signal.new()

	for name, projectile in pairs(new.Projectiles) do
		local caster = projectile.Caster

		local activeCastIds = {}
		new._ActiveCastIds[name] = activeCastIds

		caster.LengthChanged:Connect(function(activeCast, lastPoint, rayDir, displacement, segmentVelocity)
			if not activeCastIds[activeCast] then return end
			ProjectileRender.updatePosition(activeCastIds[activeCast], CFrame.lookAt(lastPoint, rayDir))
		end)

		caster.CastTerminating:Connect(function(activeCast)
			ProjectileRender.removeProjectile(player, activeCastIds[activeCast])
		end)
	end

	return new
end

function Gun:FireProjectile(projectileName, ...)
	local activeCast = self.Projectiles[projectileName].Caster:Fire(...)
	local activeCastId = HttpService:GenerateGUID()
	self._ActiveCastIds.Bullet[activeCast] = activeCastId

	ProjectileRender.createProjectile(activeCastId, ReplicatedStorage.Projectiles[projectileName])

	return activeCast, activeCastId
end

function Gun:Shoot(projectileName, origin, direction, castBehvaiour)
	local activeCast, activeCastId = self:FireProjectile(projectileName, origin, direction, self.BulletVelocity, castBehvaiour)
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
	self:SetValue("Aiming", aiming)
end

function Gun:GetMode()
	return self.FiringModes[self.CurrentMode]
end

function Gun:SetCurrentMode(index)
	assert (
		self.FiringModes[index],
		string.format("'%d' is not a valid index in FiringModes for %s", index, StringUtils.formatAddress(self, "Gun"))
	)

	self.CurrentMode = index
	self.OnModeChanged:Fire(self.FiringModes[index])

	local ToolRemotes = self.Instance.Remotes
	ToolRemotes.ChangeMode:FireServer(self.FiringModes[index])
end

function Gun:ChangeMode(firingMode)
	local index = table.find(self.FiringModes, firingMode)
	assert (
		index,
		string.format("'%s' is not a valid firing mode for %s", tostring(firingMode), StringUtils.formatAddress(self, "Gun"))
	)
	self:SetCurrentMode(index)
end

function Gun:NextMode()
	local nextIndex = (self.CurrentMode + 1) % #self.FiringModes
	if nextIndex == 0 then nextIndex = 1 end
	self:ChangeMode(nextIndex)
end

return Gun