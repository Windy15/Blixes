local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Modules.Collisions.FastCastRedux)
local Signal = require(ReplicatedStorage.Modules.General.GoodSignal)

local UpdatePosition = ReplicatedStorage.Remotes.Projectile.UpdatePosition
local RemoveProjectile = ReplicatedStorage.Remotes.Projectile.RemoveProjectile

local ToolClass = require(ReplicatedStorage.Tools.ToolClass)

local Gun = setmetatable({
	Damage = 0,
	FireRate = 1,
	
	CurrentMode = 1,
	Modes = {"Semi"},

	BulletVelocity = 100
}, ToolClass)

Gun.__index = Gun
Gun.ToolType = "Gun"

function Gun.new(new)
	new.Casters = {
		Bullet = FastCast.new()
	}

	new.OnShot = Signal.new()
	new.OnReload = Signal.new()

	new._ActiveCastIds = {}
	for name, caster in pairs(new.Casters) do
		local activeCastIds = {}
		new._ActiveCastIds[name] = activeCastIds

		caster.LengthChanged:Connect(function(activeCast, lastPoint, rayDir, displacement, segmentVelocity)
			if not activeCastIds[activeCast] then activeCastIds[activeCast] = HttpService:GenerateGUID() end

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= new.Player then
					UpdatePosition:FireClient(activeCastIds[activeCast], ReplicatedStorage.Projectiles[name], CFrame.lookAt(lastPoint, rayDir))
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
	local caster = self.Casters.Bullet
	local activeCast = caster:Fire(origin, direction, self.BulletVelocity, castBehvaiour)
end

function Gun:SetAiming(aiming)
	self.Aiming = aiming
end

return Gun