--!native

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local LoadModuleFolders = {
	ClientScripts.GameLoader,
    ReplicatedStorage.Modules,
	ClientScripts.VisualEffects,
    ClientScripts.RenderHandlers,
	ReplicatedStorage.Players,
    ReplicatedStorage.ToolClasses
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