local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AntiCheatFolder = ServerScriptService.AntiCheat

local ServerSettings =  require(ServerScriptService.ServerSettings)

local function requireModules(folder)
	for _, module in ipairs(folder:GetDescendants()) do
		if module:IsA("ModuleScript") then
			require(module)
		end
	end
end

local LoadModuleFolders = {
	ReplicatedStorage.Modules,
	ServerScriptService.Datastore,
	ReplicatedStorage.Entities,
	ServerScriptService.ToolClasses,
}

if ServerSettings.AntiCheat then
	requireModules(AntiCheatFolder)
end

for _, folder in ipairs(LoadModuleFolders) do
	requireModules(folder)
end