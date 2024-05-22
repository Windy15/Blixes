--!native
--!nonstrict

local Region = require(script.Parent.RegionClass)

local BlockRegion = setmetatable({}, Region)
BlockRegion.__index = BlockRegion

function BlockRegion.new(cframe: CFrame, size: Vector3)
    return setmetatable(Region.new{
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

return BlockRegion