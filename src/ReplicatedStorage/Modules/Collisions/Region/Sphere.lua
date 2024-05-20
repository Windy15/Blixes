--!native
--!nonstrict

local Region = require(script.Parent.RegionClass)

local SphereRegion = setmetatable({}, Region)
SphereRegion.__index = SphereRegion

function SphereRegion.new(cframe: CFrame, size: Vector3)
    return setmetatable(Region.new{
        CFrame = cframe,
        Size = size
    }, SphereRegion)
end

function SphereRegion:IsPointInRegion(point: Vector3): boolean
    return (point - self.CFrame.Position).Magnitude <= self.Size
end

function SphereRegion:GetTouchingParts(params: OverlapParams)
    return workspace:GetPartBoundsInRadius(self.CFrame.Position, self.Size, params)
end

return SphereRegion