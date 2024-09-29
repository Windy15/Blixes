--!native
--!strict

type PartRegionImpl = {
	__index: PartRegionImpl,

	new: (part: BasePart) -> PartRegion,
	IsPointInRegion: (self: PartRegion, point: Vector3) -> boolean,
	GetTouchingParts: (self: PartRegion, params: OverlapParams) -> {BasePart},
	GetPlayersInRegion: (self: PartRegion) -> {Player},
}

export type PartRegion = typeof(setmetatable({} :: {
	Part: BasePart,
}, {} :: PartRegionImpl)
)
local PartRegion = {} :: PartRegionImpl
PartRegion.__index = PartRegion

function PartRegion.new(part: BasePart)
    return setmetatable({
        Part = part
    }, PartRegion)
end

function PartRegion:IsPointInRegion(point)
    local part = self.Part
    if (point - part.Position).Magnitude < 0.05 then return true end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.BruteForceAllSlow = true
	params.FilterDescendantsInstances = {part}

	local vectorToCenter = (part.Position - point).Unit * part.Size.Magnitude * 2
	return workspace:Raycast(point - vectorToCenter, vectorToCenter, params) ~= nil
end

function PartRegion:GetTouchingParts(params)
    return workspace:GetPartsInPart(self.Part, params)
end

function PartRegion:GetPlayersInRegion()
	local players = {}
	for _, char in ipairs(workspace.Players:GetChildren()) do
		if self:IsPointInRegion(char:GetPivot().Position) then
			table.insert(players, char)
		end
	end
	return players
end

return PartRegion