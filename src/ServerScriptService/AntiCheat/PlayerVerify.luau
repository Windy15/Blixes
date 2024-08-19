--!native

local ServerScriptService = game:GetService("ServerScriptService")

local PlayerRollback = require(script.Parent.PlayerRollback)
local ServerSettings = require(ServerScriptService.ServerSettings)

local PlayerVerify = {}

local function searchRecForPart(rec: PlayerRollback.Recording, part: BasePart)
	for _, partRec in ipairs(rec.Parts) do
		if partRec.Part == part then
			return partRec
		end
	end
	return nil
end

function PlayerVerify.verifyPosition(player: Player, originPart: BasePart, expectedPositionDifference: number): boolean
	local char = player.Character
	if not char then error(`Player {player} does not have a character`, 2) end

	if ServerSettings.AntiCheat == false then
		return true
	end

	local ping = player:GetNetworkPing()
	local pingTime = os.clock() - ping

	local partRollback = PlayerRollback[player]

	-- BINARY SEARCH
	-------------------------------------
	local closestRecording: PlayerRollback.Recording? = nil
	do
		local min = 1
		local max = #partRollback
		local val = nil

		while min <= max do
			local mid = math.floor((min + max) / 2)
			closestRecording = partRollback[mid]
			val = (closestRecording :: PlayerRollback.Recording).Time
			if val == pingTime then
				break
			elseif val > pingTime then
				max = mid - 1
			elseif val < pingTime then
				min = mid + 1
			end
		end
	end
	-------------------------------------
	if not closestRecording then return false end

	local originPartRollback: PlayerRollback.PartRec? = searchRecForPart(closestRecording, originPart)

	if not originPartRollback or (originPartRollback.CFrame.Position - originPart.Position).Magnitude > expectedPositionDifference then
		return false
	end

	return true
end

local function isProperNum(num: number)
	return num < math.huge
end

function PlayerVerify.checkRemoteType<T>(val: T, valtype: string, remote: RemoteEvent | RemoteFunction | UnreliableRemoteEvent, player: Player): T
	if typeof(val) == valtype then
		if type(val) == "number" and not isProperNum(val) then
			error(`Player {player} entered '{val}' number for remote {remote:GetFullName()}`, 2)
		else
			return val
		end
	else
		error(`Player {player} didn't enter type '{valtype}' for remote {remote:GetFullName()}: (entered value '{typeof(val)}: {val}')`, 2)
	end
end

return PlayerVerify