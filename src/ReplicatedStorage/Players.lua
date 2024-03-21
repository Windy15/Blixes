local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.GoodSignal)

local PlayersMethods = {
	PlayerLoaded = Signal.new(),
	PlayerSaved = Signal.new()
}
PlayersMethods.__index = PlayersMethods
PlayersMethods.__len = function(t)
	local playerAmount = 0
	
	for _ in pairs(t) do
		playerAmount += 1
	end
	
	return playerAmount
end

local Players = setmetatable({}, PlayersMethods)

return Players