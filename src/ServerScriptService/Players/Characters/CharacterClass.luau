--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Replicator = require(ServerScriptService.Components.Replicator)

type CharacterImpl = {
    __index: CharacterImpl,
    __type: "Character",

    new: (player: Player) -> Character,
    SetValue: (self: Character, key: string, value: any) -> (),
    TakeDamage: (self: Character, damage: number, attack: Attack?) -> (),
}

export type Character = typeof(setmetatable({} :: {
    Player: Player,
    Instance: Model,

    Replicator: Replicator.Replicator,
}, {} :: CharacterImpl))

export type Attack = {
    IgnoreForcefield: boolean?
}

local Character = {} :: CharacterImpl
Character.__index = Character
Character.__type = "Character"

function Character.new(player)
    assert(player.Character, `Player {player} has no Character`)
    local self = setmetatable({
        Player = player,
        Instance = player.Character,
    }, Character)

    local ReplicateValue = Instance.new("RemoteEvent", player.Character)
    self.Replicator = Replicator.new(self, ReplicateValue)

    return self
end

function Character:SetValue(key, value)
    self[key] = value
    self.Replicator:Replicate(key, value)
end

function Character:TakeDamage(damage: number, attack)
    local humanoid = self.Instance:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    if attack then
        if attack.IgnoreForcefield then
            humanoid.Health = math.max(humanoid.Health - damage, 0)
            return
        end
    end
    humanoid:TakeDamage(damage)
end

return Character