local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunClass = require(ReplicatedStorage.ToolClasses.GunClass)

local HoneyBadger = setmetatable({
	ToolName = "HoneyBadger"
}, GunClass)
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new(config)
	return setmetatable(GunClass.new(config), HoneyBadger)
end

return HoneyBadger