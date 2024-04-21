local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetList = {
    Assets = {},
    IdNames = {
        "SoundId",
        "AnimationId",
        "TextureId",
        "MeshId",
        "Image"
    }
}

local FoldersToLoad = {
    ReplicatedStorage.Tools,
    ReplicatedStorage.Projectiles
}

local addedAssets = {}

for _, folder in ipairs(FoldersToLoad) do
    for _, asset in ipairs(folder:GetDescendants()) do
        for _, idName in ipairs(AssetList.IdNames) do
            local success, id = pcall(function()
                return asset[idName]
            end)

            if success and not addedAssets[id] then
                table.insert(AssetList.Assets, {
                    Instance = asset,
                    Id = id,
                })
                addedAssets[id] = true
            end
        end
    end
end

return AssetList