local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PropertiesClass = require(ReplicatedStorage.Modules.General.PropertiesClass)

local Character = {}
Character.__index = Character

function Character.new(player)
    local new = setmetatable(PropertiesClass.new({
        Player = player,
        Instance = player.Character,
    }), Character)

    return new
end

return Character