local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Characters = require(ReplicatedStorage.Entities.Players.Characters)
local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)
local ToolClass = require(ServerScriptService.ToolClasses.ToolClass)

local CreateProjectile = ReplicatedStorage.Remotes.Projectiles.CreateProjectile
local UpdatePosition = ReplicatedStorage.Remotes.Projectiles.UpdatePosition
local RemoveProjectile = ReplicatedStorage.Remotes.Projectiles.RemoveProjectile

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
			Caster = FastCast.new(),
			HitConnection = nil
		}
	}
	new._ActiveCastIds = {}

	if new.Projectiles.Bullet then
		new.Projectiles.Bullet.HitConnection = new.Projectiles.Bullet.Caster.RayHit:Connect(function(activeCast, result)
			activeCast:Terminate()
			local char = Characters:GetCharFromInstance(result.Instance)
			if not char then return end

			char:TakeDamage(new.Damage)
		end)
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

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= activeCastIds[activeCast].player then
					UpdatePosition:FireClient(player, activeCastIds[activeCast].id, CFrame.lookAt(lastPoint, rayDir))
				end
			end
		end)

		caster.CastTerminating:Connect(function(activeCast)
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= activeCastIds[activeCast].player then
					RemoveProjectile:FireClient(player, activeCastIds[activeCast].id)
				end
			end
		end)
	end

	return new
end

function Gun:FireProjectile(projectileName, ...)
	local activeCast = self.Projectiles[projectileName].Caster:Fire(...)
	local activeCastId = HttpService:GenerateGUID()
	self._ActiveCastIds.Bullet[activeCast] = {
		id = activeCastId,
		player = self.Player
	}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self.Player then
			CreateProjectile:FireClient(activeCastId, ReplicatedStorage.Projectiles[projectileName])
		end
	end

	return activeCast, activeCastId
end

function Gun:Shoot(projectileName, origin, direction, castBehvaiour)
	local projectile = self.Projectiles[projectileName]
	local activeCast, activeCastId = self:FireProjectile(projectile.Caster, origin, direction, self.BulletVelocity, castBehvaiour)
end

function Gun:Reload()
	if self.Reloading then return end
	self.Reloading = true

	task.delay(self.ReloadTime, function()
		self.Reloading = false
	end)
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