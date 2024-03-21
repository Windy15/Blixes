local UpdateModule = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UpdateModule")

UpdateModule.OnClientSignal:Connect(function(module, newTable, key)
	if key then
		module[key] = newTable[key]
	else
		for i, v in pairs(newTable) do
			module[i] = v
		end
	end
end)