local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyRemotes = ReplicatedStorage.Remotes.Currency

local PlayerData = {}
PlayerData.__index = PlayerData

function PlayerData.new(player)
    return setmetatable({
        Player = player,

        DateJoined = DateTime.now().UnixTimestampMillis,
        LastJoined = DateTime.now().UnixTimestampMillis,

        Blixes = 1000, BlixesEarned = 1000,
        Tix = 100,
    }, PlayerData)
end

function PlayerData:SetCurrency(currency, val)
    assert(self[currency], `'{currency}' is not a valid currency for player {self.Player.Name}`)
    local oldVal = self[currency]
    self[currency] = val
    CurrencyRemotes.Changed:Fire(oldVal, self[currency])
end

function PlayerData:AddCurrency(currency, val)
    assert(self[currency], `'{currency}' is not a valid currency for player {self.Player.Name}`)
    local oldVal = self[currency]
    self[currency] += val
    CurrencyRemotes.Changed:Fire(oldVal, self[currency])
end

return PlayerData