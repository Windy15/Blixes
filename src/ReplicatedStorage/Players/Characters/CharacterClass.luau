local Character = {}
Character.__index = Character

function Character.new(player)
    local new = setmetatable({
        Player = player,
        Instance = player.Character,
    }, Character)

    return new
end

return Character