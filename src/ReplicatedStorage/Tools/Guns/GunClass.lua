local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolClass = require(ReplicatedStorage.Tools.ToolClass)

local Gun = setmetatable({
	Damage = 0,
	FireRate = 1,
	
	CurrentMode = 1,
	Modes = {"Semi"}
}, ToolClass)

Gun.__index = Gun
Gun.ToolType = "Gun"

function Gun.new(new)
	
	
	return setmetatable(ToolClass.new(new), Gun)
end

function Gun:Fire(origin, direction)
	
end

function Gun:SetAiming(aiming)

end

return Gun