local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local player = Players.LocalPlayer
local ProjectileRender = require(player.RenderHandlers.ProjectileRender)

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

	new.CurrentMode = config.CurrentMode or 1
	new.FiringModes = config.FiringModes or {"Semi"}

	new.BulletVelocity = config.BulletVelocity or 100

	new.Casters = config.Casters or {
		Bullet = FastCast.new()
	}
	new.CurrentCaster = config.CurrentCaster or "Bullet"
	new._ActiveCastIds = {}

	new.OnShot = Signal.new()
	new.OnReloading = Signal.new()
	new.OnModeChanged = Signal.new()

	for name, caster in pairs(new.Casters) do
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

function Gun:Shoot(origin, direction, castBehvaiour)
	local caster = self.Casters[self.CurrentCaster]
	local activeCast = caster:Fire(origin, direction, self.BulletVelocity, castBehvaiour)

	local activeCastId = HttpService:GenerateGUID()
	self._ActiveCastIds.Bullet[activeCast] = activeCastId

	ProjectileRender.createProjectile(activeCastId, ReplicatedStorage.Projectiles[self.CurrentCaster])
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