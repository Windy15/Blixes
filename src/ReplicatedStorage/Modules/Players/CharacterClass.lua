local Character = {}
Character.__index = Character

function Character.new(player)
    return setmetatable({
        Player = player,
        Instance = player.Character,
    }, Character)
end

return Character