local Region = {
	CFrame = CFrame.identity,
	Size = Vector3.zero,
	RegionType = "Box"
}
Region.__index = Region

function Region.new(new)
	return setmetatable(new, Region)
end

function Region:PointInRegion(point)
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
	elseif self.RegionType == "Instance" then
		local collisionPoint = Instance.new("Part")
		collisionPoint.Position = point
		collisionPoint.Size = Vector3.new(0.05, 0.05, 0.05)
		collisionPoint.Anchored = true
		collisionPoint.Transparency = 1
		collisionPoint.CanCollide = false
		collisionPoint.CanQuery = false
		collisionPoint.Parent = workspace

		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = {collisionPoint}
		params.BruteForceAllSlow = true

		local pointFound = table.find(workspace:GetPartsInPart(self.Instance, params))

		collisionPoint:Destroy()

		return pointFound and true
	else
		error("Invalid Region Type")
	end
end

function Region:GetTouchingParts(params)
	params = params or OverlapParams.new()
	
	if self.RegionType == "Box" then
		return workspace:GetPartBoundsInBox(self.CFrame, self.Size, params)
	elseif self.RegionType == "Sphere" then
		return workspace:GetPartBoundsInRadius(self.CFrame, self.Size, params)
	elseif self.RegionType == "Instance" then
		return workspace:GetPartsInPart(self.Instance, params)
	else
		error("Invalid Region Type")
	end
end

function Region:GetPlayers()
	local players = {}

	for _, char in ipairs(workspace.Players:GetChildren()) do
		if self:PointInRegion(char:GetPivot().Position) then
			table.insert(players, char)
		end
	end

	return players
end

return Region