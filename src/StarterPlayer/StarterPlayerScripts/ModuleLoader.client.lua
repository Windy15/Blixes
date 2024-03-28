local StarterPlayer = game:GetService("StarterPlayer")
local ClientScripts = StarterPlayer.StarterPlayerScripts

local renders = ClientScripts.RenderHandlers:GetChildren()

for _, handler in ipairs(renders) do
    require(handler)
end