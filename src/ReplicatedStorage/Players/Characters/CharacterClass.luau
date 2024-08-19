local Character = {}
Character.__index = Character

function Character.new(player)
    local self = setmetatable({
        Player = player,
        Instance = player.Character,
    }, Character)

    return self
end

return Character