local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesPlayerData = ReplicatedStorage.Remotes.PlayerData

local DataMeta = {}
DataMeta.__index = DataMeta
local PlayerData = setmetatable({}, DataMeta)

local function updateData(player, data)
    PlayerData[player] = data
end

RemotesPlayerData.ReplicateData.OnClientEvent:Connect(updateData)
PlayerData[Players.LocalPlayer] = RemotesPlayerData.DataLoaded.OnClientEvent:Wait()

return PlayerData