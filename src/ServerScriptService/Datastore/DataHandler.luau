local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService.Players.PlayerData)
local PlayerDataClass = require(ServerScriptService.Datastore.PlayerDataClass)

local RemotesPlayerData = ReplicatedStorage.Remotes.PlayerData

local DataHandler = {}

local function createPlayerData(player)
    local playerData = PlayerDataClass.new(player)
    PlayerData[player] = playerData
    RemotesPlayerData.DataLoaded:FireClient(player, playerData)
    playerData:CreateInventory({}, 10)
end

for _, player in ipairs(Players:GetPlayers()) do
    createPlayerData(player)
end

Players.PlayerAdded:Connect(createPlayerData)

return DataHandler