local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesPlayerData = ReplicatedStorage.Remotes.PlayerData

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

function PlayerData:SetCash(val: number)
    self.Cash = val
    RemotesPlayerData.CashSet:FireClient(self.Player, self.Cash)
end

function PlayerData:AddCash(add: number)
    self.Cash += add
    RemotesPlayerData.CashSet:FireClient(self.Player, self.Cash, true) -- If client should play animation
end

function PlayerData:SetBlixes(val: number)
    self.Cash = val
    RemotesPlayerData.BlixesSet:FireClient(self.Player, self.Blixes)
end

function PlayerData:AddBlixes(add: number)
    self.Cash += add
    RemotesPlayerData.BlixesSet:FireClient(self.Player, self.Blixes, true)
end

return PlayerData