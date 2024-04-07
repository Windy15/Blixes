local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local CharacterList = {
	CharacterAdded = Signal.new(),
	CharacterRemoved = Signal.new()
}
CharacterList.__index = CharacterList
CharacterList.__len = function(t)
	local totalChars = 0

	for _, char in pairs(t) do
		if char.Instance then
			totalChars += 1
		end
	end

	return totalChars
end

function CharacterList.new()
    return setmetatable({}, CharacterList)
end

function CharacterList:GetCharFromInstance(instance, descendantsCheck)
	for _, char in pairs(self) do
		if descendantsCheck and instance:IsDescendantOf(char) or instance.Parent == char then
			return char
		end
	end
end

return CharacterList