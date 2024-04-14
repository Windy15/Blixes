local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterClass = require(script.CharacterClass)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local MetaData = {
	CharacterAdded = Signal.new(),
	CharacterRemoved = Signal.new()
}

local Characters = setmetatable({}, MetaData)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local char = CharacterClass.new(player)
		Characters[player.Name] = char
		Characters.CharacterAdded:Fire(char)
	end)

	player.CharacterRemoving:Connect(function()
		local char = Characters[player.Name]
		Characters[player.Name] = nil
		Characters.CharacterRemoved:Fire(char)
	end)
end)

function MetaData:GetCharFromInstance(instance, shallow)
	if shallow then
		for _, char in ipairs(self) do
			if instance:IsDescendantOf(char) then
				return char
			end
		end
	else
		for _, char in ipairs(self) do
			if instance.Parent == char then
				return char
			end
		end
	end

	return nil
end

return Characters