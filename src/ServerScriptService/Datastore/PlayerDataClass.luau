--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryClass = require(ServerScriptService.Players.Inventory.InventoryClass)
local RemotesPlayerData = ReplicatedStorage.Remotes.PlayerData
local RemotesInventory = RemotesPlayerData.Inventory

type PlayerDataImpl = {
    new: (player: Player) -> PlayerData,
    CreateInventory: (self: PlayerData, ...any) -> (),
    SetCash: (self: PlayerData, cash: number) -> (),
    AddCash: (self: PlayerData, cashAdd: number) -> (),
    SetBlixes: (self: PlayerData, blixesAdd: number) -> (),
    AddBlixes: (self: PlayerData, blixesAdd: number) -> (),

    __index: PlayerDataImpl,
}

export type PlayerData = typeof(setmetatable({} :: {
    Player: Player,

    DateJoined: DateTime,
    LastJoined: DateTime,

    Cash: number,
    Blixes: number,

    Inventory: {[any]: any}?
}, {} :: PlayerDataImpl))

local PlayerData = {} :: PlayerDataImpl
PlayerData.__index = PlayerData

function PlayerData.new(player): PlayerData
    return setmetatable({
        Player = player,

        DateJoined = DateTime.now(),
        LastJoined = DateTime.now(),

        Cash = 1000,
        Blixes = 5,

        Inventory = nil
    }, PlayerData)
end

function PlayerData:CreateInventory(...)
    self.Inventory = InventoryClass.new(...)
    RemotesInventory.InventoryCreated:FireClient(self.Player, self.Inventory)
end

function PlayerData:SetCash(cash: number)
    self.Cash = cash
    RemotesPlayerData.CashSet:FireClient(self.Player, self.Cash)
end

function PlayerData:AddCash(cashAdd: number)
    self.Cash += cashAdd
    RemotesPlayerData.CashSet:FireClient(self.Player, self.Cash, true) -- If client should play animation
end

function PlayerData:SetBlixes(blixes: number)
    self.Cash = blixes
    RemotesPlayerData.BlixesSet:FireClient(self.Player, self.Blixes)
end

function PlayerData:AddBlixes(blixesAdd: number)
    self.Cash += blixesAdd
    RemotesPlayerData.BlixesSet:FireClient(self.Player, self.Blixes, true)
end

return PlayerData