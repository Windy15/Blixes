local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.GoodSignal)

local Projectile = {
	Instance = nil
}
Projectile.__index = Projectile
Projectile.__type = "Projectile"

function Projectile.new(new)
	return setmetatable(new, Projectile)
end

return Projectile