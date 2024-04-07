local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterClass = require(ReplicatedStorage.Entities.Player.CharacterClass)
local CharacterList = require(ReplicatedStorage.Entities.CharactersListClass)
local GlobalCharacters = require(ReplicatedStorage.Entities.GlobalCharacters)

local Characters = CharacterList.new()

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local char = CharacterClass.new(player)
		Characters[player.Name] = CharacterClass.new(player)
		Characters.CharacterAdded:Fire(char)
		GlobalCharacters:AddCharacter(char)
	end)

	player.CharacterRemoving:Connect(function()
		GlobalCharacters:RemoveCharacter(Characters[player.Name])
		Characters.CharacterRemoved:Fire(Characters[player.Name])
		Characters[player.Name] = nil
	end)
end)

return Characters