--!native
--!strict

type SphereRegionImpl = {
	__index: SphereRegionImpl,

	new: (cframe: CFrame, size: Vector3) -> SphereRegion,
	IsPointInRegion: (self: SphereRegion, point: Vector3) -> boolean,
	GetTouchingParts: (self: SphereRegion, params: OverlapParams) -> {BasePart},
	GetPlayersInRegion: (self: SphereRegion) -> {Player},
}

export type SphereRegion = typeof(setmetatable({} :: {
	CFrame: CFrame,
	Size: Vector3,
}, {} :: SphereRegionImpl))

local SphereRegion = {} :: SphereRegionImpl
SphereRegion.__index = SphereRegion

function SphereRegion.new(cframe: CFrame, size: Vector3)
    return setmetatable({
        CFrame = cframe,
        Size = size
    }, SphereRegion)
end

function SphereRegion:IsPointInRegion(point)
    return (point - self.CFrame.Position).Magnitude <= self.Size.Magnitude
end

function SphereRegion:GetTouchingParts(params)
    return workspace:GetPartBoundsInRadius(self.CFrame.Position, self.Size, params)
end

function SphereRegion:GetPlayersInRegion()
	local players = {}
	for _, char in ipairs(workspace.Players:GetChildren()) do
		if self:IsPointInRegion(char:GetPivot().Position) then
			table.insert(players, char)
		end
	end
	return players
end

return SphereRegion