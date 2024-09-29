--!native
--!strict

export type Recording = {
	Time: number,
	Parts: {PartRec},
	HumanoidData: {
		State: Enum.HumanoidStateType,
		WalkSpeed: number,
		JumpHeight: number,
	}
}

export type PartRec = {
	Part: BasePart,
	CFrame: CFrame,
	Size: Vector3,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RECORDING_LIMIT = 600 -- 10 seconds of rollback on 60 FPS
local MAX_FPS = 60

local PlayerRollback = {} :: {[Player]: {Recording}}

Players.PlayerAdded:Connect(function(player)
	local rollback = table.create(RECORDING_LIMIT)
	PlayerRollback[player] = rollback

	local rollbackConnection: RBXScriptConnection? = nil

	local function finishRollback()
		if rollbackConnection then
			rollbackConnection:Disconnect()
			rollbackConnection = nil
			debug.profilebegin("Clearing rollback")
			table.clear(rollback)
			debug.profileend()
		end
	end

	player.CharacterAdded:Connect(function(char)
		local lastTime = os.clock()

		rollbackConnection = RunService.PreAnimation:Connect(function()
			local deltaTime = os.clock() - lastTime
			if 1 / MAX_FPS - deltaTime > 0.001 then return end -- delta time might take a little shorter than expected fps
			lastTime = os.clock()

			debug.profilebegin("Adding new recording")

			if #rollback >= RECORDING_LIMIT then
				table.remove(rollback, 1)
			end

			local humanoid = char:FindFirstChildWhichIsA("Humanoid")
			local state = humanoid and humanoid:GetState()
			if not char.Parent or not humanoid or state == Enum.HumanoidStateType.Dead then
				finishRollback()
				return
			end

			local newRecording = {
				Time = os.clock(),
				Parts = {},
				HumanoidData = {
					State = state :: Enum.HumanoidStateType,
					WalkSpeed = humanoid.WalkSpeed,
					JumpHeight = humanoid.JumpHeight,
				}
			}

			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanQuery then
					table.insert(newRecording.Parts, {
						Part = part,
						CFrame = part.CFrame,
						Size = part.Size
					})
				end
			end

			table.insert(rollback, newRecording)

			debug.profileend()
		end)
	end)

	player.CharacterRemoving:Connect(finishRollback)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerRollback[player] = nil
end)

return PlayerRollback