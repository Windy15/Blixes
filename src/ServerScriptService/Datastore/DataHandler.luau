local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService.Players.PlayerData)
local PlayerDataClass = require(ServerScriptService.Datastore.PlayerDataClass)

local RemotesPlayerData = ReplicatedStorage.Remotes.PlayerData

local DataHandler = {}

local PlayersLoaded = setmetatable({}, {__mode = "k"})

RemotesPlayerData.GetLoadedData.OnServerInvoke = function(player: Player)
    if PlayersLoaded[player] then
        error(`Already loaded data for player {player}`)
    end
    PlayersLoaded[player] = coroutine.running()

    local data = table.clone(PlayerData[player] or coroutine.yield()) -- Thread will be resumed when player's data gets loaded
    data.Inventory = data.Inventory.Capacity

    return data
end

local function loadPlayerData(player)
    local playerData = PlayerDataClass.new(player)
    PlayerData[player] = playerData
    playerData:CreateInventory({}, 10)
    local loadingThread = PlayersLoaded[player]
    if type(loadingThread) == "thread" then
        coroutine.resume(loadingThread, playerData)
        PlayersLoaded[player] = true -- Don't hold on to thread reference
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    loadPlayerData(player)
end

Players.PlayerAdded:Connect(loadPlayerData)

return DataHandler