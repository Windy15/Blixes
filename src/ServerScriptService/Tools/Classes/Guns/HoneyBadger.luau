local ServerScriptService = game:GetService("ServerScriptService")
local GunClass = require(ServerScriptService.Tools.Classes.GunClass)

local HoneyBadger = setmetatable({
	ToolName = "HoneyBadger"
}, GunClass)
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new(config)
	local self = setmetatable(GunClass.new({
		Damage = 20,
		FireRate = 20,
		Modes = {"Auto", "Semi"},

		DisplayName = "Honey Badger"
	}), HoneyBadger)

	if config then
		for k, v in config do
			self[k] = v
		end
	end

	return self
end

return HoneyBadger