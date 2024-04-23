--!nocheck

local ContentProvider = game:GetService("ContentProvider")
local AssetList = require(script.AssetList)

local GameLoader = {
    AssetsLoaded = 0,
    FailedAssets = {}
}

local timedOutAssets = {}

local function onAssetLoaded(id, status)
    if status == Enum.AssetFetchStatus.Success then
        GameLoader.AssetsLoaded += 1
    elseif status == Enum.AssetFetchStatus.TimedOut then
        table.insert(timedOutAssets, id)
    end
end

for _, asset in ipairs(AssetList.Assets) do
    if ContentProvider:GetAssetFetchStatus(asset.Id) == Enum.AssetFetchStatus.Success then
        continue
    end
    ContentProvider:PreloadAsync({asset.Id}, onAssetLoaded)
end

local currentAsset = nil

local function onTimedOutAsset(_, status)
    if status == Enum.AssetFetchStatus.Success then
        GameLoader.AssetsLoaded += 1
    else
        table.insert(GameLoader.FailedAssets, currentAsset)
    end
end

for _, asset in ipairs(timedOutAssets) do
    currentAsset = asset
    ContentProvider:PreloadAsync({asset.Id}, onTimedOutAsset)
end

for _, asset in ipairs(GameLoader.FailedAssets) do
    warn (
        string.format (
            "Could not load asset %s: %s",
            string.match(currentAsset.Instance:GetFullName(), ".-%.(.+)"),
            asset.Id
        )
    )
end

return GameLoader