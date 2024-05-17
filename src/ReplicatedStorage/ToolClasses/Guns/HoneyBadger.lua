local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunClass = require(ReplicatedStorage.ToolClasses.GunClass)

local HoneyBadger = {
	ToolName = "HoneyBadger"
}
HoneyBadger.__index = HoneyBadger

function HoneyBadger.new(config)
	local new = setmetatable(GunClass.new({
		Damage = 20,
		FireRate = 20,
		Modes = {"Auto", "Semi"},

		DisplayName = "Honey Badger"
	}), HoneyBadger)

	if config then
		for k, v in pairs(config) do
			new[k] = v
		end
	end

	return new
end

return HoneyBadger