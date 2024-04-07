local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterList = require(ReplicatedStorage.Entities.CharactersListClass)

local GlobalCharacters = CharacterList.new()

function GlobalCharacters:AddCharacter(charObject)
    self[charObject.Instance] = charObject
    self.CharacterAdded:Fire(charObject)
end

function GlobalCharacters:RemoveCharacter(charObject)
    self[charObject.Instance] = nil
    self.CharacterRemoved:Fire(charObject)
end

return GlobalCharacters