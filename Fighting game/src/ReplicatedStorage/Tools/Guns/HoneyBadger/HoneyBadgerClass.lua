local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunClass = require(ReplicatedStorage.Tools.Guns.GunClass)

local HoneyBadger = setmetatable({
	Damage = 20,
	FireRate = 20,
	
	Modes = {"Auto", "Semi"}
}, GunClass)

HoneyBadger.__index = HoneyBadger
HoneyBadger.ToolName = "HoneyBadger"

function HoneyBadger.new(new)
	return setmetatable(GunClass.new(new), HoneyBadger)
end

return HoneyBadger