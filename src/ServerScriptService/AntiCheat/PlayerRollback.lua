local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Rollback = {
	RecordingLimit = 10000,
	LastDeltaTime = 0
}

Players.PlayerAdded:Connect(function(player)
	local PlayerRollback = table.create(Rollback.RecordingLimit)
	Rollback[player] = PlayerRollback

	local rollbackConnection = nil

	player.CharacterAdded:Connect(function(char)
		rollbackConnection = RunService.Stepped:Connect(function(deltaTime)
			Rollback.LastDeltaTime = deltaTime
			if #PlayerRollback >= Rollback.RecordingLimit then
				table.remove(PlayerRollback, 1)
			end

			local CurrentTime = {
				Time = os.clock(),
				Parts = {}
			}

			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanQuery then
					CurrentTime.Parts[part] = {CFrame = part.CFrame}
				end
			end

			table.insert(PlayerRollback, CurrentTime)
		end)
	end)

	player.CharacterRemoving:Connect(function()
		if rollbackConnection then
			rollbackConnection:Disconnect()
		end
	end)
end)

return Rollback