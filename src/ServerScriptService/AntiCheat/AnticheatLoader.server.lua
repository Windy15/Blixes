local ServerScriptService = game:GetService("ServerScriptService")

local Anticheat = script.Parent
local ServerSettings = require(ServerScriptService.ServerSettings)

if ServerSettings.AntiCheat then
    for _, module in ipairs(Anticheat:GetChildren()) do
        if module:IsA("ModuleScript") then
            require(module)
        end
    end
end