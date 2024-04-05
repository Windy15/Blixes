local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ClientScripts = StarterPlayer.StarterPlayerScripts

local function requireModules(folder)
	for _, module in ipairs(folder:GetDescendants()) do
		if module:IsA("ModuleScript") then
			require(module)
		end
	end
end

local LoadModuleFolders = {
    ReplicatedStorage.Modules,
    ClientScripts.RenderHandlers,
    ReplicatedStorage.ToolClasses
}

for _, folder in ipairs(LoadModuleFolders) do
    requireModules(folder)
end