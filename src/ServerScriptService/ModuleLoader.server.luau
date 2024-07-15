--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function requireFolder(folder)
	if folder:IsA("ModuleScript") then
		require(folder)
	end

	for _, module in ipairs(folder:GetChildren()) do
		if module:IsA("ModuleScript") then
			require(module)
		elseif module:IsA("Folder") then
			requireFolder(module)
		end
	end
end

local LoadModuleFolders : {Folder | ModuleScript} = {
	ReplicatedStorage.Modules,
	ServerScriptService.Players,
	ServerScriptService.Anticheat,
	ServerScriptService.Datastore,
	ServerScriptService.ToolClasses,
	ServerScriptService.ServerData,
}

print("LOADING MODULES")
print("------------------------------------------")

for _, folder in ipairs(LoadModuleFolders) do
	local start = os.clock()
    requireFolder(folder)
	local finish = os.clock()
	print(string.format("%s: %g", folder.Name, finish - start))
end

print("------------------------------------------")