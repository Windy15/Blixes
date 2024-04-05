local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local CreateProjectile = ReplicatedStorage.Remotes.Projectiles.CreateProjectile
local UpdatePosition = ReplicatedStorage.Remotes.Projectiles.UpdatePosition
local RemoveProjectile = ReplicatedStorage.Remotes.Projectiles.RemoveProjectile

local ToolClass = require(ServerScriptService.ToolClasses.ToolClass)

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

function Gun:Shoot(origin, direction, castBehvaiour)
	local caster = self.Casters[self.CurrentCaster]
	local activeCast = caster:Fire(origin, direction, self.BulletVelocity, castBehvaiour)

	local activeCastId = HttpService:GenerateGUID()
	self._ActiveCastIds.Bullet[activeCast] = {
		id = activeCastId,
		player = self.Player
	}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self.Player then
			CreateProjectile:FireClient(activeCastId, ReplicatedStorage.Projectiles[self.CurrentCaster])
		end
	end
end

function Gun:Reload()
	if self.Reloading then return end
	self.Reloading = true

	task.delay(self.ReloadTime, function()
		self.Reloading = false
	end)
end

function Gun:SetAiming(aiming)
	self:SetValue("Aiming", aiming)
end

function Gun:ChangeMode(firingMode)
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