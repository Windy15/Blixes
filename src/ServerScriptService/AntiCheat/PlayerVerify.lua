local PlayerRollback = require(script.Parent.PlayerRollback)

local PlayerVerify = {}

local positionPrecision = 5

function PlayerVerify:VerifyPosition(player, originPart, clientPosition)
	local char = player.Character
	if not char then return end
	
	local ping = player:GetNetworkPing()
	local pingTime = os.clock() - ping
	
	local partRollback = PlayerRollback[player]
	
	local lastRecording = nil
	local lastTime = 0
	
	for markedTime, rec in pairs(partRollback) do
		if markedTime <= pingTime and markedTime >= lastTime then
			lastRecording = rec
			lastTime = markedTime
		end
	end
	
	local originPartRollback = lastRecording[originPart]
	
	if not originPartRollback then
		return false
	end
	
	if (originPartRollback.Position - clientPosition).Magnitude > char.Humanoid.WalkSpeed then
		return false
	end
	
	return lastRecording
end

return PlayerVerify