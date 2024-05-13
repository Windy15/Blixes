--!native

export type Recording = {
	Time: number,
	Parts: {
		[BasePart]: {
			CFrame: CFrame,
			Size: Vector3
		}
	}
}

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

		rollbackConnection = RunService.PostSimulation:ConnectParallel(function()
			local deltaTime = os.clock() - lastTime
			if deltaTime < 1 / MAX_FPS then return end
			lastTime = os.clock()

			debug.profilebegin("Adding new recording")

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

			debug.profileend()
		end)
	end)

	player.CharacterRemoving:Connect(function()
		if rollbackConnection then
			rollbackConnection:Disconnect()
			debug.profilebegin("Clearing rollback")
			table.clear(rollback)
			debug.profileend()
		end
	end)
end)

return PlayerRollback