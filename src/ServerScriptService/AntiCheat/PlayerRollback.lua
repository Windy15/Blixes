local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RECORDING_LIMIT = 600 -- 10 seconds of rollback on 60 FPS
local MAX_FPS = 60

local PlayerRollback = {}

Players.PlayerAdded:Connect(function(player)
	local rollback = table.create(RECORDING_LIMIT)
	PlayerRollback[player] = rollback

	local rollbackConnection = nil

	player.CharacterAdded:Connect(function(char)
		local lastTime = os.clock()

		rollbackConnection = RunService.Stepped:Connect(function()
			local deltaTime = os.clock() - lastTime
			if deltaTime < 1 / MAX_FPS then return end
			lastTime = os.clock()
			PlayerRollback.LastDeltaTime = deltaTime

			if #rollback >= RECORDING_LIMIT then
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