--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local GunClass = require(ServerScriptService.Tools.Classes.GunClass)
local ProjCaster = require(ReplicatedStorage.Modules.Collisions.ProjCaster)
local ProjShooter = require(ServerScriptService.Components.Shooters.ProjShooter)

local Bullet = ReplicatedStorage.Visuals.Projectiles.Bullet

local BaseStats = {
	Damage = 20,
	FireRate = 20,
	ReloadTime = 1,
}

local HoneyBadger = {
	ToolName = "HoneyBadger",
	BaseStats = BaseStats
}

function HoneyBadger.new(config, initConfig)
	local self = GunClass.new({
		ToolClass = HoneyBadger,
		DisplayName = "Honey Badger",

		Damage = BaseStats.Damage,
		FireRate = BaseStats.FireRate,
		ReloadTime = BaseStats.ReloadTime,

		FiringMode = EnumState.new(GameEnums.FiringMode.Auto, GameEnums.FiringMode.Semi),
	}, initConfig)

	self.Shooter = ProjShooter.new(self, ProjCaster.new({
		DestroyOnHit = true,
	}), Bullet)

	if config then
		for k, v in config do
			self[k] = v
		end
	end

	return self
end

return HoneyBadger