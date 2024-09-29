--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterClass = require(script.CharacterClass)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local CharMethods = {
	CharacterAdded = Signal.new(),
	CharacterRemoved = Signal.new()
}
CharMethods.__index = CharMethods

local Characters = setmetatable({
	List = {} :: {[Player]: CharacterClass.Character}
}, CharMethods)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local char = CharacterClass.new(player)
		Characters.List[player] = char
		CharMethods.CharacterAdded:Fire(char)
	end)

	player.CharacterRemoving:Connect(function()
		local char = Characters[player]
		Characters.List[player] = nil
		CharMethods.CharacterRemoved:Fire(char)
	end)
end)

function CharMethods:GetCharFromInstance(instance: Instance, descendants: boolean?): CharacterClass.Character?
	if descendants then
		for _, char: CharacterClass.Character in self do
			if instance:IsDescendantOf(char.Instance) then
				return char
			end
		end
	else
		for _, char: CharacterClass.Character in self do
			if instance.Parent == char.Instance then
				return char
			end
		end
	end

	return nil
end

return Characters