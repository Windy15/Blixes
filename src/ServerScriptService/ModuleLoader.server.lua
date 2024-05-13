local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function requireFolder(folder)
	for _, module in ipairs(folder:GetChildren()) do
		if module:IsA("ModuleScript") then
			require(module)
		elseif module:IsA("Folder") then
			requireFolder(module)
		end
	end
end

local LoadModuleFolders = {
	ReplicatedStorage.Modules,
	ReplicatedStorage.Players,
	ServerScriptService.Datastore,
	ServerScriptService.ToolClasses,
}

for _, folder in ipairs(LoadModuleFolders) do
	requireFolder(folder)
end