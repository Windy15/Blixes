local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

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

	new.FiringModes = config.FiringModes or {"Semi"}
	new.CurrentMode = config.CurrentMode or new.FiringModes[1]

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

function Gun:FireCast(caster, ...)
	local activeCast = caster:Fire(...)
	local activeCastId = HttpService:GenerateGUID()
	self._ActiveCastIds.Bullet[activeCast] = activeCastId

	return caster, activeCastId
end

function Gun:Shoot(projectileName, origin, direction, castBehvaiour)
	local projectile = self.Projectiles[projectileName]
	local activeCast, activeCastId = self:FireCast(projectile.Caster, origin, direction, self.BulletVelocity, castBehvaiour)

	ProjectileRender.createProjectile(activeCastId, ReplicatedStorage.Projectiles[projectileName])
end

function Gun:Reload()
	if self.Reloading then return end
	self.Reloading = true

	local reloadAnim = self.Player.Character:LoadAnimation(self.Instance.Animations.ReloadAnimation)
	reloadAnim:Play()

	task.delay(self.ReloadTime, function()
		self.Reloading = false
	end)
end

function Gun:SetAiming(aiming)
	self:SetValue("Aiming", aiming)
end

function Gun:ChangeMode(firingMode)
	local ToolRemotes = self.Instance.Remotes
	ToolRemotes.ChangeMode:FireServer(firingMode)

	assert (
		table.find(self.FiringModes, firingMode),
		string.format("'%s' is not a valid firing mode for Gun: %s", firingMode, string.match(tostring(self), "0x.+"))
	)
	self.CurrentMode = firingMode
	self.OnModeChanged:Fire(firingMode)
end

function Gun:NextMode()
	local nextIndex = (table.find(self.FiringModes, self.CurrentMode) + 1) % #self.FiringModes
	if nextIndex == 0 then nextIndex = 1 end
	self:ChangeMode(self.FiringModes[nextIndex])
end

return Gun