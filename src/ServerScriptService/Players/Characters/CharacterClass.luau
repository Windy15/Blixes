--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modifier = require(ReplicatedStorage.Components.Modifier)
local Replicator = require(ServerScriptService.Components.Replicator)

type CharacterImpl = {
    __index: CharacterImpl,
    __type: "Character",

    new: (player: Player) -> Character,
    SetValue: (self: Character, key: string, value: any) -> (),
    TakeDamage: (self: Character, damage: number, attack: Attack?) -> (),
    Heal: (self: Character, amount: number, info: HealInfo?) -> (),
}

export type Character = typeof(setmetatable({} :: {
    Player: Player,
    Instance: Model,
    Humanoid: Humanoid,

    Health: number,
    MaxHealth: number,

    Replicator: Replicator.Replicator,
    Modifier: Modifier.Modifier,
}, {} :: CharacterImpl))

export type Attack = {
    IgnoreForcefield: boolean?
}

export type HealInfo = {

}

local Character = {} :: CharacterImpl
Character.__index = Character
Character.__type = "Character"

function Character.new(player)
    assert(player.Character, `Player {player} has no Character`)
    local self = setmetatable({
        Player = player,
        Instance = player.Character,
        Humanoid = player.Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid,

        Health = 100,
        MaxHealth = 100,
    }, Character)
    self.Modifier = Modifier.new(self, "TakingDamage")

    local ReplicateValue = Instance.new("RemoteEvent", player.Character)
    self.Replicator = Replicator.new(self, ReplicateValue)

    return self
end

function Character:SetValue(key, value)
    self[key] = value
    self.Replicator:Replicate(key, value)
end

local function getFinalDamage(self: Character, damage: number): number
    return self.Modifier:GetModified("TakingDamage", math.max(damage, 0))
end

function Character:TakeDamage(damage, attack)
    damage = getFinalDamage(self, damage)
    if attack then
        if attack.IgnoreForcefield then
            self.Humanoid.Health = math.max(self.Humanoid.Health - damage, 0)
            return
        end
    end
    self.Humanoid:TakeDamage(damage)
end

function Character:Heal(amount, info)
    self.Humanoid.Health += amount
end

return Character