local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientScripts = Players.LocalPlayer.PlayerScripts

local function requireModules(folder)
	for _, module in ipairs(folder:GetDescendants()) do
		if module:IsA("ModuleScript") then
			require(module)
		end
	end
end

local LoadModuleFolders = {
    ReplicatedStorage.Modules,
    ClientScripts:WaitForChild("RenderHandlers"),
	ReplicatedStorage.Entities,
    ReplicatedStorage.ToolClasses
}

for _, folder in ipairs(LoadModuleFolders) do
    requireModules(folder)
end