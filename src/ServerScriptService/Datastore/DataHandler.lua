local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InventoryClass = require(ReplicatedStorage.Players.InventoryClass)
local PlayerData = require(ReplicatedStorage.Players.PlayerData)
local PlayerDataClass = require(ServerScriptService.Datastore.PlayerDataClass)

local DataHandler = {}

Players.PlayerAdded:Connect(function(player)
    local playerData = PlayerDataClass.new(player)
    PlayerData[player] = playerData
    playerData.Inventory = InventoryClass.new({}, 10)
end)

return DataHandler