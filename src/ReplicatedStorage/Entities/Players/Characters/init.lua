local Players = game:GetService("Players")

local CharacterClass = require(script.CharacterClass)

local Characters = {}

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		Characters[player.Name] = CharacterClass.new(player)
	end)

	player.CharacterRemoving:Connect(function()
		Characters[player.Name] = nil
	end)
end)

return Characters