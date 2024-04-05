local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunClass = require(ReplicatedStorage.ToolClasses.GunClass)

local HoneyBadger = {
	ToolName = "HoneyBadger"
}
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new(config)
	config = config or {}
	local new = setmetatable(GunClass.new(config), HoneyBadger)
	new.Damage = config.Damage or 20
	new.FireRate = config.FireRate or 20
	new.Modes = {"Auto", "Semi"}

	return new
end

return HoneyBadger