local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientScripts = Players.LocalPlayer.PlayerScripts

local GunClass = require(ReplicatedStorage.Tools.Classes.GunClass)
local ProjCaster = require(ReplicatedStorage.Modules.Physics.ProjCaster)
local ProjShooter = require(ClientScripts.Components.Shooters.ProjShooter)

local Bullet = ReplicatedStorage.Visuals.Projectiles.Bullet

local HoneyBadger = {
	ToolName = "HoneyBadger"
}

function HoneyBadger.new(config)
	local self = GunClass.new(config)

	self.Shooter = ProjShooter.new(self, ProjCaster.new({
		DestroyOnHit = true,
		Tooltip = "the first ever",
	}), Bullet)

	if config then
		for k, v in config do
			self[k] = v
		end
	end

	return self
end

return HoneyBadger