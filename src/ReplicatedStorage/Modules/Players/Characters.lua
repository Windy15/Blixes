local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterClass = require(ReplicatedStorage.Modules.Players.CharacterClass)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local CharMethods = {
	PlayerLoaded = Signal.new(),
	PlayerSaved = Signal.new()
}
CharMethods.__index = CharMethods
CharMethods.__len = function(t)
	local totalChars = 0

	for _, char in pairs(t) do
		if char.Instance then
			totalChars += 1
		end
	end

	return totalChars
end

local Characters = setmetatable({}, CharMethods)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		Characters[player.Name] = CharacterClass.new(player)
	end)

	player.CharacterRemoving:Connect(function()
		Characters[player.Name] = nil
	end)
end)

return Characters