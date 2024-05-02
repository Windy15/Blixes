local PlayerRollback = require(script.Parent.PlayerRollback)

local PlayerVerify = {
	PositionPrecision = 5
}

function PlayerVerify:VerifyPosition(player, originPart, currentOrigin, expectedPositionDifference)
	local char = player.Character
	assert(char, `Player {player} does not have a character`)

	local ping = player:GetNetworkPing()
	local pingTime = os.clock() - ping

	local partRollback = PlayerRollback[player]

	local lastRecording = nil
	local lastTime = 0

	for _, rec in ipairs(partRollback) do
		if rec.Time <= pingTime and rec.Time >= lastTime then
			lastRecording = rec
			lastTime = rec.Time
		end
	end

	local originPartRollback = lastRecording.Parts[originPart]

	if not originPartRollback or (originPartRollback.Position - currentOrigin).Magnitude
		> (expectedPositionDifference or char.Humanoid.WalkSpeed + PlayerVerify.PositionPrecision) then
		return false
	end

	return lastRecording
end

function PlayerVerify:RemoteTypeCheck(val, valtype, remote, player)
	assert(type(val) == valtype, `Player {player} didn't enter type {valtype} for remote {remote:GetFullName()}`)
end

return PlayerVerify