local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunClass = require(ReplicatedStorage.Tools.Guns.GunClass)

local HoneyBadger = {
	ToolName = "HoneyBadger"
}
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new()
	return setmetatable(GunClass.new {
		Damage = 20,
		FireRate = 20,

		Modes = {"Auto", "Semi"}
	}, HoneyBadger)
end

return HoneyBadger