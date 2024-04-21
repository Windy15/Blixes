local ServerScriptService = game:GetService("ServerScriptService")
local GunClass = require(ServerScriptService.ToolClasses.GunClass)

local HoneyBadger = {
	ToolName = "HoneyBadger"
}
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new(config)
	local new = setmetatable(GunClass.new(config or {}), HoneyBadger) setmetatable(GunClass.new({
		Damage = 20,
		FireRate = 20,
		Modes = {"Auto", "Semi"}
	}), HoneyBadger)

	for k, v in pairs(config) do
		new[k] = v
	end

	return new
end

return HoneyBadger