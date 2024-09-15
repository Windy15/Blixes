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
	FireRate = 20
}

local HoneyBadger = setmetatable({
	ToolName = "HoneyBadger",
	BaseStats = BaseStats
}, GunClass)
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new(config)
	local self = {
		DisplayName = "Honey Badger",

		Damage = BaseStats.Damage,
		FireRate = BaseStats.FireRate,

		Modes = EnumState.new(GameEnums.GunMode.Auto, GameEnums.GunMode.Semi),
	}
	self.Shooter = ProjShooter.new(self, ProjCaster.new({
		DestroyOnHit = true,
	}), Bullet)

	if config then
		for k, v in config do
			self[k] = v
		end
	end

	return setmetatable(GunClass.new(self), HoneyBadger)
end

return HoneyBadger