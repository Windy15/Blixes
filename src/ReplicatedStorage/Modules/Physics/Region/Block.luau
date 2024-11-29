--!native
--!strict

type BlockRegionImpl = {
	__index: BlockRegionImpl,

	new: (cframe: CFrame, size: Vector3) -> BlockRegion,
	IsPointInRegion: (self: BlockRegion, point: Vector3) -> boolean,
	GetTouchingParts: (self: BlockRegion, params: OverlapParams) -> {BasePart},
	GetPlayersInRegion: (self: BlockRegion) -> {Player},
}

export type BlockRegion = typeof(setmetatable({} :: {
	CFrame: CFrame,
	Size: Vector3,
}, {} :: BlockRegionImpl))

local BlockRegion = {} :: BlockRegionImpl
BlockRegion.__index = BlockRegion

function BlockRegion.new(cframe: CFrame, size: Vector3)
    return setmetatable({
        CFrame = cframe,
        Size = size
    }, BlockRegion)
end

function BlockRegion:IsPointInRegion(point: Vector3): boolean
    local newPoint = self.CFrame:PointToObjectSpace(point)
		local TopCorner = self.Size / 2
		local BottomCorner = -TopCorner
		return
			newPoint.X >= BottomCorner.X and
			newPoint.X <= TopCorner.X and
			newPoint.Y >= BottomCorner.Y and
			newPoint.Y <= TopCorner.Y and
			newPoint.Z >= BottomCorner.Z and
			newPoint.Z <= TopCorner.Z
end

function BlockRegion:GetTouchingParts(params: OverlapParams): {BasePart}
    return workspace:GetPartBoundsInBox(self.CFrame, self.Size, params)
end

function BlockRegion:GetPlayersInRegion(): {Player}
	local players = {}
	for _, char in ipairs(workspace.Players:GetChildren()) do
		if self:IsPointInRegion(char:GetPivot().Position) then
			table.insert(players, char)
		end
	end
	return players
end

return BlockRegion