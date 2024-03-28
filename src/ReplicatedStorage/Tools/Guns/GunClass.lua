local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local Signal = require(ReplicatedStorage.Modules.General.GoodSignal)

local CreateProjectile = ReplicatedStorage.Remotes.Projectile.CreateProjectile
local UpdatePosition = ReplicatedStorage.Remotes.Projectile.UpdatePosition
local RemoveProjectile = ReplicatedStorage.Remotes.Projectile.RemoveProjectile

local ToolClass = require(ReplicatedStorage.Tools.ToolClass)

local Gun = setmetatable({
	Damage = 0,
	FireRate = 1,

	CurrentMode = 1,
	FiringModes = {"Semi"},

	BulletVelocity = 100
}, ToolClass)

Gun.__index = Gun
Gun.ToolType = "Gun"

function Gun.new(new)
	new.Casters = {
		Bullet = FastCast.new()
	}
	new.CurrentCaster = "Bullet"

	new.OnShot = Signal.new()
	new.OnReload = Signal.new()

	new._ActiveCastIds = {}
	for name, caster in pairs(new.Casters) do
		local activeCastIds = {}
		new._ActiveCastIds[name] = activeCastIds

		caster.LengthChanged:Connect(function(activeCast, lastPoint, rayDir, displacement, segmentVelocity)
			if not activeCastIds[activeCast] then return end

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= new.Player then
					UpdatePosition:FireClient(activeCastIds[activeCast], CFrame.lookAt(lastPoint, rayDir))
				end
			end
		end)

		caster.CastTerminating:Connect(function(activeCast)
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= new.Player then
					RemoveProjectile:FireClient(player, activeCastIds[activeCast])
				end
			end
		end)
	end

	return setmetatable(ToolClass.new(new), Gun)
end

function Gun:Fire(origin, direction, castBehvaiour)
	local caster = self.Casters[self.CurrentCaster]
	local activeCast = caster:Fire(origin, direction, self.BulletVelocity, castBehvaiour)

	local activeCastId = HttpService:GenerateGUID()
	self._ActiveCastIds.Bullet[activeCast] = activeCastId

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self.Player then
			CreateProjectile:FireClient(activeCastId, ReplicatedStorage.Projectiles[self.CurrentCaster])
		end
	end
end

function Gun:SetAiming(aiming)
	self.Aiming = aiming
end

function Gun:ChangeMode(firingMode)
	assert (
		table.find(self.FiringModes, firingMode),
		string.format("'%s' is not a valid firing mode for Gun: %s", firingMode, string.match(tostring(self), "0x.+"))
	)
	self.CurrentMode = firingMode

	if not RunService:IsServer() then
		local ToolRemotes = self.Instance.Remotes
		ToolRemotes.ChangeMode:FireServer(firingMode)
	end
end

function Gun:NextMode()
	local nextIndex = (table.find(self.FiringModes, self.CurrentMode) + 1) % #self.FiringModes
	if nextIndex == 0 then nextIndex = 1 end
	self:ChangeMode(self.FiringModes[nextIndex])
end

return Gun