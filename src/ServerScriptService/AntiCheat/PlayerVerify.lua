local PlayerRollback = require(script.Parent.PlayerRollback)

local PlayerVerify = {
	PositionPrecision = 5
}

function PlayerVerify.verifyPosition(player: Player, originPart: BasePart, currentOrigin: Vector3, expectedPositionDifference: number): {[string]: any} | boolean
	local char = player.Character
	assert(char, `Player {player} does not have a character`)

	local ping = player:GetNetworkPing()
	local pingTime = os.clock() - ping

	local partRollback = PlayerRollback[player]

	-- BINARY SEARCH
	-------------------------------------
	local min = 1
	local max = #partRollback
	local closestRecording = nil
	local val = nil

	while min <= max do
		local mid = math.floor((min + max) / 2)
		closestRecording = PlayerRollback[mid]
		val = closestRecording.Time
		if val == pingTime then
			break
		elseif val > pingTime then
			max = mid - 1
		elseif val < pingTime then
			min = mid + 1
		end
	end
	-------------------------------------

	local originPartRollback = closestRecording.Parts[originPart]

	if not originPartRollback or (originPartRollback.CFrame.Position - currentOrigin).Magnitude
		> expectedPositionDifference then
		return false
	end

	return closestRecording
end

function PlayerVerify.checkRemoteType<T>(val: T, valtype: string, remote: RemoteEvent | RemoteFunction | UnreliableRemoteEvent, player: Player): boolean
	return (assert(
		typeof(val) == valtype,
		`Player {player} didn't enter type '{valtype}' for remote {remote:GetFullName()}: (entered value '{typeof(val)}: {val}')`
	)) -- () to make assert return one value
end

return PlayerVerify