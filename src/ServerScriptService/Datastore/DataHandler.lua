local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService.Players.PlayerData)
local PlayerDataClass = require(ServerScriptService.Datastore.PlayerDataClass)

local RemotesPlayerData = ReplicatedStorage.Remotes.PlayerData

local DataHandler = {}

Players.PlayerAdded:Connect(function(player)
    local playerData = PlayerDataClass.new(player)
    PlayerData[player] = playerData
    RemotesPlayerData.DataLoaded:FireClient(player, playerData)
    playerData:CreateInventory({}, 10)
end)

return DataHandler