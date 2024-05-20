--!native
--!nonstrict

local Region = require(script.Parent.RegionClass)

local PartRegion = setmetatable({}, Region)
PartRegion.__index = PartRegion

function PartRegion.new(part: BasePart)
    return setmetatable(Region.new{
        Part = part
    }, PartRegion)
end

function PartRegion:IsPointInRegion(point: Vector3): boolean
    local part = self.Part
    if (point - part.Position).Magnitude < 0.05 then return true end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.BruteForceAllSlow = true
	params.FilterDescendantsInstances = {part}

	local vectorToCenter = (part.Position - point).Unit * part.Size.Magnitude * 2
	return workspace:Raycast(point - vectorToCenter, vectorToCenter, params) ~= nil
end

function PartRegion:GetTouchingParts(params: OverlapParams): {BasePart}
    return workspace:GetPartsInPart(self.Part, params)
end

return PartRegion