local ServerScriptService = game:GetService("ServerScriptService")
local GunClass = require(ServerScriptService.ToolClasses.GunClass)

local HoneyBadger = {
	ToolName = "HoneyBadger"
}
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new()
	local new = setmetatable(GunClass.new({
		Damage = 20,
		FireRate = 20,
		Modes = {"Auto", "Semi"}
	}), HoneyBadger)

	return new
end

return HoneyBadger