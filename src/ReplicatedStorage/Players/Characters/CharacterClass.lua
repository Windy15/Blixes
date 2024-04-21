local Character = {}
Character.__index = Character

function Character.new(player)
    local new = setmetatable({
        Player = player,
        Instance = player.Character,
    }, Character)

    return new
end

function Character:TakeDamage(dmg)
    self.Instance.Humanoid:TakeDamage(math.clamp(dmg, 0, math.huge))
end

return Character