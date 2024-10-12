local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientScripts = Players.LocalPlayer.PlayerScripts

local InventoryClass = require(ClientScripts.Players.Inventory.InventoryClass)

local RemotesPlayerData = ReplicatedStorage.Remotes.PlayerData

local DataMeta = {}
DataMeta.__index = DataMeta
local PlayerData = setmetatable({}, DataMeta)

local playerData = RemotesPlayerData.GetLoadedData:InvokeServer()

if playerData.Inventory then
    playerData.Inventory = InventoryClass.new(playerData.Inventory)
end

PlayerData[Players.LocalPlayer] = playerData

return PlayerData