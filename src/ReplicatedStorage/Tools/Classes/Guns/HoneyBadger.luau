local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunClass = require(ReplicatedStorage.Tools.Classes.GunClass)
local ProjCaster = require(ReplicatedStorage.Modules.Collisions.ProjCaster)
local ProjShooter = require(ReplicatedStorage.Tools.Components.Shooters.ProjShooter)

local Bullet = ReplicatedStorage.Visuals.Projectiles.Bullet

local HoneyBadger = setmetatable({
	ToolName = "HoneyBadger"
}, GunClass)
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new(config)
	local self = {}

	self.Shooter = ProjShooter.new(self, ProjCaster.new({
		DestroyOnHit = true,
	}), Bullet)

	if config then
		for k, v in config do
			self[k] = v
		end
	end

	return setmetatable(GunClass.new(config), HoneyBadger)
end

return HoneyBadger