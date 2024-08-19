local Character = {}
Character.__index = Character

function Character.new(player)
    local self = setmetatable({
        Player = player,
        Instance = player.Character,
    }, Character)

    return self
end

function Character:TakeDamage(damage: number)
    local humanoid = self.Instance:FindFirstChildWhichIsA("Humanoid")
    humanoid:TakeDamage(damage)
end

return Character