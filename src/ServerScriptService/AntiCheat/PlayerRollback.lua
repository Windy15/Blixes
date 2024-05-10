local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerRollback = {
	RecordingLimit = 10000,
	LastDeltaTime = 0
}

Players.PlayerAdded:Connect(function(player)
	local rollback = table.create(PlayerRollback.RecordingLimit)
	PlayerRollback[player] = rollback

	local rollbackConnection = nil

	player.CharacterAdded:Connect(function(char)
		rollbackConnection = RunService.Stepped:Connect(function(deltaTime)
			PlayerRollback.LastDeltaTime = deltaTime
			if #rollback >= PlayerRollback.RecordingLimit then
				table.remove(rollback, 1)
			end

			local newRecording = {
				Time = os.clock(),
				Parts = {}
			}

			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanQuery then
					newRecording.Parts[part] = {
						CFrame = part.CFrame,
						Size = part.Size
					}
				end
			end

			table.insert(rollback, newRecording)
		end)
	end)

	player.CharacterRemoving:Connect(function()
		if rollbackConnection then
			rollbackConnection:Disconnect()
			table.clear(rollback)
		end
	end)
end)

return PlayerRollback