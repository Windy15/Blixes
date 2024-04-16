local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Rollback = {}

local RollbackLimit = 10000

-- use new Instance.new("WorldModel")

Players.PlayerAdded:Connect(function(player)
	local PlayerRollback = {}
	Rollback[player] = PlayerRollback

	player.CharacterAdded:Connect(function(char)
		RunService.Stepped:Connect(function()
			local count = 0

			for _ in pairs(PlayerRollback) do
				count += 1
			end

			if count >= RollbackLimit then
				local lowest = nil

				for i, recording in pairs(PlayerRollback) do
					if not lowest or i < lowest then
						lowest = i
					end
				end

				if lowest then
					PlayerRollback[lowest] = nil
				end
			end

			local CurrentTime = {}
			PlayerRollback[os.clock()] = CurrentTime

			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("Part") and part.CanQuery then
					CurrentTime[part] = part.CFrame
				end
			end
		end)
	end)
end)

return Rollback