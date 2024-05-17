local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local List = require(ReplicatedStorage.Modules.General.ListClass)

local RemotesPlayerData = ReplicatedStorage.Remotes.PlayerData

local DataMeta = {}
local PlayerData = List.new({}, DataMeta)

local function updateData(player, data)
    PlayerData[player] = data
end

RemotesPlayerData.ReplicateData.OnClientEvent:Connect(updateData)
PlayerData[Players.LocalPlayer] = RemotesPlayerData.DataLoaded.OnClientEvent:Wait()

return PlayerData