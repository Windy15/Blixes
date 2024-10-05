--!strict

type CharacterImpl = {
    __index: CharacterImpl,
    __type: "Character",

    new: (player: Player) -> Character,
    SetValue: (self: Character, key: string, value: any) -> (),
}

export type Character = typeof(setmetatable({} :: {
    Player: Player,
    Instance: Model,
}, {} :: CharacterImpl))

local Character = {} :: CharacterImpl
Character.__index = Character
Character.__type = "Character"

function Character.new(player)
    assert(player.Character, `Player {player} has no Character`)
    local self = setmetatable({
        Player = player,
        Instance = player.Character,
    }, Character)

    return self
end

function Character:SetValue(key, value)
    self[key] = value
end

return Character