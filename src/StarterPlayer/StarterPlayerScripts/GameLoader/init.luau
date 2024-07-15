--!nocheck

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer

local GameLoader = {
    AssetsLoaded = 0,
    FailedAssets = {}
}

local PreloadFolders = {
    plr.PlayerGui,
    ReplicatedStorage.Tools,
    ReplicatedStorage.Projectiles,
    workspace.Map,
}

local timedOutAssets = {}

local function onAssetLoaded(asset, status)
    if status == Enum.AssetFetchStatus.Success then
        GameLoader.AssetsLoaded += 1
    elseif status == Enum.AssetFetchStatus.TimedOut then
        table.insert(timedOutAssets, asset)
    end
end

for _, folder in ipairs(PreloadFolders) do
    for _, asset in ipairs(folder:GetDescendants()) do
        ContentProvider:PreloadAsync({asset}, onAssetLoaded)
    end
end

local currentAsset = nil

local function onTimedOutAsset(id, status)
    if status == Enum.AssetFetchStatus.Success then
        GameLoader.AssetsLoaded += 1
    else
        table.insert(GameLoader.FailedAssets, {Instance = currentAsset, ContentId = id})
    end
end

for _, asset in ipairs(timedOutAssets) do
    currentAsset = asset
    ContentProvider:PreloadAsync({asset}, onTimedOutAsset)
end

for _, asset in ipairs(GameLoader.FailedAssets) do
    warn (
        string.format (
            "Could not load asset %s: %s",
            string.match(asset.Instance:GetFullName(), ".-%.(.+)"),
            asset.ContentId
        )
    )
end

return GameLoader