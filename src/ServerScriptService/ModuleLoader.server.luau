--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function requireFolder(folder: Folder | Actor)
	if folder:IsA("ModuleScript") then
		require(folder)
	end

	for _, module in folder:GetChildren() do
		if module:IsA("ModuleScript") then
			require(module)
		elseif module:IsA("Folder") or module:IsA("Actor") then
			requireFolder(module)
		end
	end
end

local LoadModuleFolders : {Folder | ModuleScript} = {
	ReplicatedStorage.Modules,
	ServerScriptService.Datastore,
	ServerScriptService.Anticheat,
	ServerScriptService.Tools,
	ServerScriptService.ServerData,
	ServerScriptService.Players, -- Players start loading after server finishes loading
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