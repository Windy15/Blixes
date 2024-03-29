local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ClientScripts = StarterPlayer.StarterPlayerScripts

local Modules = ReplicatedStorage.Modules

require(Modules.Players.Characters)

local renders = ClientScripts.RenderHandlers:GetChildren()

for _, handler in ipairs(renders) do
    require(handler)
end