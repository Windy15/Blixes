local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyRemotes = ReplicatedStorage.Remotes.Currency

local PlayerData = {}
PlayerData.__index = PlayerData

function PlayerData.new(player)
    return setmetatable({
        Player = player,

        DateJoined = DateTime.now().UnixTimestampMillis,
        LastJoined = DateTime.now().UnixTimestampMillis,

        Cash = 1000,
        Blixes = 5,

        Inventory = nil
    }, PlayerData)
end

local ERR_INVALID_CURRENCY = "%s is not a valid currency for player %s"

function PlayerData:SetCurrency(currency, val)
    assert(self[currency], string.format(ERR_INVALID_CURRENCY, currency, self.Player.Name))
    local oldVal = self[currency]
    self[currency] = val
    CurrencyRemotes.Changed:FireClient(self.Player, oldVal, self[currency])
end

function PlayerData:AddCurrency(currency, val)
    assert(self[currency], string.format(ERR_INVALID_CURRENCY, currency, self.Player.Name))
    local oldVal = self[currency]
    self[currency] += val
    CurrencyRemotes.Changed:FireClient(self.Player.Name, oldVal, self[currency])
end

return PlayerData