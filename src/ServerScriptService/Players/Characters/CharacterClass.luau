local Character = {}
Character.__index = Character

function Character.new(player)
    local new = setmetatable({
        Player = player,
        Instance = player.Character,
    }, Character)

    return new
end

function Character:TakeDamage(damage: number)
    local humanoid = self.Instance:FindFirstChildWhichIsA("Humanoid")
    humanoid:TakeDamage(damage)
end

return Character