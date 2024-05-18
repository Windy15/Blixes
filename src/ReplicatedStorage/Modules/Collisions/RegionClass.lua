--!native

local Region = {}
Region.__index = Region

function Region.new(regionType, cframeOrPart, size)
	local new = setmetatable({
		RegionType = regionType,
	}, Region)
	if typeof(cframeOrPart) == "CFrame" then
		new.CFrame = cframeOrPart
		new.Size = size
	else
		new.Part = cframeOrPart
	end
	return new
end

local function pointInPart(point, part)
	if (point - part.Position).Magnitude < 0.05 then return true end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.BruteForceAllSlow = true
	params.FilterDescendantsInstances = {part}

	local vectorToCenter = (part.Position - point).Unit * part.Size.Magnitude * 2
	return workspace:Raycast(point - vectorToCenter, vectorToCenter, params) ~= nil
end

local function invalidRegionType(region)
	error(`'{region.RegionType}' is not a valid region type`)
end

function Region:IsPointInRegion(point)
	if self.RegionType == "Box" then
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
	elseif self.RegionType == "Sphere" then
		return (point - self.CFrame.Position).Magnitude <= self.Size
	elseif self.RegionType == "Part" then
		return pointInPart(point, self.Part)
	else
		return invalidRegionType(self)
	end
end

function Region:GetTouchingParts(params)
	params = params or OverlapParams.new()

	if self.RegionType == "Box" then
		return workspace:GetPartBoundsInBox(self.CFrame, self.Size, params)
	elseif self.RegionType == "Sphere" then
		return workspace:GetPartBoundsInRadius(self.CFrame, self.Size, params)
	elseif self.RegionType == "Part" then
		return workspace:GetPartsInPart(self.Part, params)
	else
		return invalidRegionType(self)
	end
end

function Region:GetPlayersInRegion()
	local players = {}
	for _, char in ipairs(workspace.Players:GetChildren()) do
		if self:PointInRegion(char:GetPivot().Position) then
			table.insert(players, char)
		end
	end
	return players
end

return Region