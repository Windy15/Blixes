--!native
--!nonstrict

local Region = {}
Region.__index = Region

function Region.new(config)
	setmetatable(config, Region)
end

function Region:GetPlayersInRegion(): {Player}
	local players = {}
	for _, char in ipairs(workspace.Players:GetChildren()) do
		if self:PointInRegion(char:GetPivot().Position) then
			table.insert(players, char)
		end
	end
	return players
end

return Region