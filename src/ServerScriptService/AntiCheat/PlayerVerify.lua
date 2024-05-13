--!native

local PlayerRollback = require(script.Parent.PlayerRollback)

local PlayerVerify = {}

function PlayerVerify.verifyPosition(player: Player, originPart: BasePart, expectedPositionDifference: number): PlayerRollback.Recording | boolean
	local char = player.Character
	if not char then error(`Player {player} does not have a character`, 2) end

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
		closestRecording = partRollback[mid]
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
	if not closestRecording then return false end

	local originPartRollback = closestRecording.Parts[originPart]

	if not originPartRollback or (originPartRollback.CFrame.Position - originPart.Position).Magnitude
		> expectedPositionDifference then
		return false
	end

	return closestRecording
end

function PlayerVerify.checkRemoteType<T>(val: T, valtype: string, remote: RemoteEvent | RemoteFunction | UnreliableRemoteEvent, player: Player): T
	if typeof(val) == valtype then
		return val
	else
		error(`Player {player} didn't enter type '{valtype}' for remote {remote:GetFullName()}: (entered value '{typeof(val)}: {val}')`, 2)
	end
end

return PlayerVerify