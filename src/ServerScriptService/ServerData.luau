local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)

local ServerRemotes = ReplicatedStorage.Remotes.GlobalServerData

local MainServers = MemoryStoreService:GetSortedMap("MainServers")

local ID_CHARS = string.split("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", "")
local ID_LEN = 5
local ID_UPDATE_TIME = 120
local ID_EXPIRATION = ID_UPDATE_TIME + 30

local SERVER_LIST_SIZE = 30

local REFRESH_LIST_COOLDOWN = 5
local DATA_RETRIEVE_COOLDOWN = 5
local JOIN_SERVER_COOLDOWN = 3

local ServerData = {
    SERVER_ID = "",
    CachedServerList = table.create(SERVER_LIST_SIZE),
    Location = nil,
}

local function generateServerId()
    local str = ""
    for _ = 1, ID_LEN do
        str ..= ID_CHARS[math.random(#ID_CHARS)]
    end
    return str
end

export type ServerData = {
    JobId: string,
    ServerId: string,
    PlayerCount: number,
    Location: {
        Country: string,
        Region: string,
        City: string,
    },
}

local function saveServerId()
    local playerCount = #Players:GetPlayers()
    MainServers:SetAsync(ServerData.SERVER_ID, {
        JobId = game.JobId,
        ServerId = ServerData.SERVER_ID,
        PlayerCount = #Players:GetPlayers(),
        Location = ServerData.Location,
    }, ID_EXPIRATION, playerCount)
end

local function safeCall(f, ...): (boolean, ...any)
    local isSuccess, data = false, nil
    for _ = 1, 3 do
        local retrieved = {pcall(f, ...)}
        local success = retrieved[1]
        if success then
            isSuccess = true
            table.remove(retrieved, 1)
            data = retrieved
            break
        else
            warn(retrieved[2], debug.traceback("(SafeCall Error)", 2))
        end
    end
    if isSuccess then
        return true, table.unpack(data)
    else
        return false
    end
end

do
    local function createServerId()
        local newId = generateServerId()
        while MainServers:GetAsync(newId) do
            newId = generateServerId()
        end
        ServerData.SERVER_ID = newId
        saveServerId()
    end

    local lastUpdate = 0
    local function serverIdUpdate()
        local currentTime = DateTime.now().UnixTimestamp
        if currentTime - lastUpdate > ID_UPDATE_TIME then
            lastUpdate = currentTime
            safeCall(saveServerId)
        end
    end

    local success = pcall(createServerId)
    while not success do
        success = pcall(createServerId)
    end
    RunService.PostSimulation:Connect(serverIdUpdate)
end

do
    type URLResponse = {
        status: boolean,
        country: string,
        regionName: string,
        city: string,
    }

    local ServerLocationURL = "http://ip-api.com/json/?fields=16409"

    local success, data = pcall(HttpService.GetAsync, HttpService, ServerLocationURL)
    if success then
        data = HttpService:JSONDecode(data) :: URLResponse
        if data.status then
            ServerData.Location = {
                Country = data.country,
                Region = data.regionName,
                City = data.city,
            }
        end
    end
end

game:BindToClose(function()
    safeCall(MainServers.RemoveAsync, MainServers, ServerData.SERVER_ID)
end)

LogService.MessageOut:Connect(function(message, messageType)
    if messageType == Enum.MessageType.MessageOutput then
        if message == "/serverdata" then
            print(StringUtils.displayTable(ServerData))
        end
    end
end)


local RefreshCooldowns = {}
local LastRefresh = 0

ServerRemotes.GetServerList.OnServerInvoke = function(player: Player)
    local cooldown = RefreshCooldowns[player]
    if cooldown and os.clock() - cooldown < REFRESH_LIST_COOLDOWN then
        return false, "Please wait before refreshing"
    end
    RefreshCooldowns[player] = os.clock()

    if os.clock() - LastRefresh < 3 and ServerData.CachedServerList then
        return true, ServerData.CachedServerList -- return a cached list for multiple players refreshing at the same time
    end

    local lowerBound = {sortKey = 0}
    local upperBound = {sortKey = Players.MaxPlayers - 1}
    local success, biggestServers = safeCall(MainServers.GetRangeAsync, MainServers, Enum.SortDirection.Descending, SERVER_LIST_SIZE, lowerBound, upperBound)

    if not success then
        return false, "Failed to retrieve server list"
    end

    for i, item in ipairs(biggestServers) do
        biggestServers[i] = item.value
    end

    ServerData.CachedServerList = biggestServers
    LastRefresh = os.clock() -- debounce only resets after a successful non-cached refresh

    return true, biggestServers
end

local function getServer(serverId: string): (boolean, ServerData | string)
    local success, serverData = safeCall(MainServers.GetAsync, MainServers, serverId)

    if not success then
        return false, "Failed to retrieve server data"
    end

    if not serverData then
        return false, "Server doesn't exist"
    end

    return true, serverData
end

local DataCooldowns = {}

ServerRemotes.GetServerData.OnServerInvoke = function(player: Player, serverId: string)
    if type(serverId) ~= "string" then return false, "Internal error" end

    local cooldown = DataCooldowns[player]
    if cooldown and os.clock() - cooldown < DATA_RETRIEVE_COOLDOWN then
        return false, "Please wait before finding server"
    end
    DataCooldowns[player] = os.clock()

    return getServer(serverId)
end

local JoinCooldowns = {}

ServerRemotes.JoinServer.OnServerInvoke = function(player: Player, serverId: string)
    if type(serverId) ~= "string" then return false, "Internal error" end

    local cooldown = JoinCooldowns[player]
    if cooldown and os.clock() - cooldown < JOIN_SERVER_COOLDOWN then
        return false, "Please wait before joining server"
    end
    JoinCooldowns[player] = os.clock()

    local jobId do
        local success, data = getServer(serverId)
        if not success then
            return false, data
        end
        jobId = data.JobId
    end

    local options = Instance.new("TeleportOptions")
    options.Name = "MainServers ("..player.Name..")"
    options.ServerInstanceId = jobId
    local success, _, teleportResult, errorMessage = safeCall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, {player}, options)

    if not success or teleportResult ~= Enum.TeleportResult.Success then
        warn("ServerData JoinServer: "..errorMessage)

        if teleportResult == Enum.TeleportResult.IsTeleporting then
            return false, "Currently Teleporting"
        elseif teleportResult == Enum.TeleportResult.GameFull then
            return false, "Server is full"
        elseif teleportResult == Enum.TeleportResult.GameEnded then
            return false, "Server no longer exists"
        elseif teleportResult == Enum.TeleportResult.GameNotFound then
            return false, "Invalid game instance id"
        end

        return false, "Failed to teleport to server"
    end

    return true, "Teleporting to server..."
end

return ServerData