--!native

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Modules.General.Logger)

local ClientScripts = Players.LocalPlayer.PlayerScripts

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
	ClientScripts.Modules,
	ClientScripts.Players, -- Load player data first
    ReplicatedStorage.Modules,
	ClientScripts.GameLoader,
    ClientScripts.RenderHandlers,
    ReplicatedStorage.Tools,
}

Logger.info("LOADING MODULES")
Logger.info("------------------------------------------")

for _, folder in ipairs(LoadModuleFolders) do
	local start = os.clock()
    requireFolder(folder)
	local finish = os.clock()
	Logger.info(string.format("%s.%s: %g", folder.Parent.Name, folder.Name, finish - start))
end

Logger.info("------------------------------------------")