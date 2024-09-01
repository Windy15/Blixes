--!native

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StudioDebug = require(ReplicatedStorage.Modules.General.StudioDebug)

local ClientScripts = Players.LocalPlayer.PlayerScripts

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
	ReplicatedStorage.Players, -- Load player data first
    ReplicatedStorage.Modules,
	ClientScripts.GameLoader,
    ClientScripts.RenderHandlers,
    ReplicatedStorage.Tools,
}

StudioDebug.log("LOADING MODULES")
StudioDebug.log("------------------------------------------")

for _, folder in ipairs(LoadModuleFolders) do
	local start = os.clock()
    requireFolder(folder)
	local finish = os.clock()
	StudioDebug.log(string.format("%s: %g", folder.Name, finish - start))
end

StudioDebug.log("------------------------------------------")