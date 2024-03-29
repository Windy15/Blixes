local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Modules.General.GoodSignal)

local RAY_CAST_NAME = "Line"
local SPHERE_CAST_NAME = "Sphere"
local BLOCK_CAST_NAME = "Block"

local RaycastHitbox = {
	Model = nil,
	RaycastParams = RaycastParams.new(),
	RayPointName = nil, -- Name of the attachments that will be a part of the hitbox (optional)

	Visualize = false, -- Debug visualizer
	RaycastOnShapecast = true, -- Whether to raycast normally for every shapecast to deal with the shapecast limitations
	UpdateAttachments = false, -- If properties or attributes of attachments updating should be taken into account (slower)
	ShallowAttachments = false, -- Whether to only get children and not descendents of "Model"

	BlockCastFaceDirection = true, -- If BlockCasting faces the direction it goes
}
RaycastHitbox.__index = RaycastHitbox

function RaycastHitbox.new(model, rayParams)
	local new = setmetatable({
		Model = model,
		RaycastParams = rayParams,

		OnHit = Signal.new()
	}, RaycastHitbox)

	return new
end

local function CreateAdornment(pos, lastPos)
	local adornment = nil
	adornment = Instance.new("LineHandleAdornment")
	adornment.CFrame = CFrame.lookAt(pos, lastPos)
	adornment.Thickness = 5
	adornment.Length = (pos - lastPos).Magnitude

	adornment.Color3 = Color3.new(1, 0, 0)
	adornment.Adornee = workspace.Terrain
	adornment.Parent = workspace.Terrain

	Debris:AddItem(adornment, 3)
end

function RaycastHitbox:StartHit(model)
	assert(self.Model, "RaycastHitbox object must have a \"Model\" before :StartHit()")

	if self._HitConnection then return end

	local Model = self.Model
	local RayParams = self.RaycastParams
	local Visualize = self.Visualize
	local RaycastOnShapecast = self.RaycastOnShapecast
	local BlockCastFaceDirection = self.BlockCastFaceDirection

	local OnHit = self.OnHit

	local RayPointsTable = {}

	local attachments = self.ShallowAttachments and self.Model:GetChildren() or self.Model:GetDescendants()

	for _, att in ipairs(attachments) do
		local rayPointType = att:GetAttribute("RayPointType")

		if self.RayPointName and att.Name ~= self.RayPointName then continue end

		if att:IsA("Attachment") and
			(rayPointType == RAY_CAST_NAME or rayPointType == SPHERE_CAST_NAME or rayPointType == BLOCK_CAST_NAME)
		then
			if not self.UpdateAttachments then
				local rayEnabled = att:GetAttribute("RayEnabled")
				rayEnabled = (rayEnabled == true or rayEnabled == nil)

				local raySize, rayOrientation = att:GetAttribute("RaySize"), att:GetAttribute("RayOrientation")

				table.insert(RayPointsTable, {
					RayEnabled = rayEnabled,
					RayPointType = rayPointType,
					Attachment = att,
					Position = att.Position,
					LastPosition = att.WorldPosition,
					RaySize = raySize or Vector3.zero,
					RayOrientation = rayOrientation and CFrame.fromOrientation(rayOrientation.X, rayOrientation.Y, rayOrientation.Z) or CFrame.identity
				})
			else
				table.insert(RayPointsTable, {
					Attachment = att,
					LastPosition = att.WorldPosition -- Last Position
				})
			end
		end
	end

	if not self.UpdateAttachments then
		self._HitConnection = RunService.Heartbeat:Connect(function(deltaTime)
			for _, point in ipairs(RayPointsTable) do
				local rayEnabled = point.RayEnabled
				rayEnabled = (rayEnabled == true or rayEnabled == nil)
				if not rayEnabled then continue end

				local partCFrame = point.Attachment.Parent.CFrame

				local pos = partCFrame.Position + point.Position
				local lastPos = point.LastPosition

				local result = nil

				if point.RayPointType == RAY_CAST_NAME then
					result = workspace:Raycast(lastPos, pos - lastPos, RayParams)

				elseif point.RayPointType == SPHERE_CAST_NAME then
					pcall(function() -- Shapecast distance limit
						result = workspace:Spherecast(lastPos, point.RaySize, pos - lastPos, RayParams)
							or RaycastOnShapecast and
							workspace:Raycast(lastPos, pos - lastPos, RayParams)
					end)

				elseif point.RayPointType == BLOCK_CAST_NAME then
					local BlockCFrame = CFrame.new(lastPos) * point.RayOrientation
					local rayDirection = pos - lastPos

					if BlockCastFaceDirection then
						BlockCFrame *= CFrame.lookAt(Vector3.zero, rayDirection.Unit)
					end

					pcall(function() -- Shapecast distance limit
						result = workspace:Blockcast (
							BlockCFrame,
							point.RaySize,
							rayDirection,
							RayParams
						) or RaycastOnShapecast and
							workspace:Raycast(lastPos, pos - lastPos, RayParams)
					end)
				end

				if Visualize then
					CreateAdornment(pos, lastPos)
				end

				if result then
					OnHit:Fire(result, point.Attachment)
				end

				point.LastPosition = pos
			end
		end)
	else
		self._HitConnection = RunService.Heartbeat:Connect(function(deltaTime)
			for _, point in ipairs(RayPointsTable) do
				local rayEnabled = point.Attachment:GetAttribute("RayEnabled")
				rayEnabled = (rayEnabled == true or rayEnabled == nil)
				if not rayEnabled then continue end

				local rayPointType = point.Attachment:GetAttribute("RayPointType")

				local part = point.Attachment.Parent

				local pos = point.Attachment.WorldPosition

				local result = nil

				if rayPointType == RAY_CAST_NAME then
					result = workspace:Raycast(pos, pos - point.LastPosition, RayParams)

				elseif rayPointType == SPHERE_CAST_NAME then
					pcall(function() -- Shapecast distance limit
						result = workspace:Spherecast (
							pos, part:GetAttribute("RaySize") or 0, pos - point.LastPosition, RayParams
						) or RaycastOnShapecast and
							workspace:Raycast(point.LastPosition, pos - point.LastPosition, RayParams)
					end)

				elseif rayPointType == BLOCK_CAST_NAME then
					local BlockSize = part:GetAttribute("RaySize") or Vector3.zero
					local BlockCFrame = part:GetAttribute("RayOrientation") or Vector3.zero

					local rayDirection = pos - point.LastPosition

					BlockCFrame = CFrame.new(point.LastPosition) * CFrame.fromOrientation(BlockCFrame.X, BlockCFrame.Y, BlockCFrame.Z)

					if BlockCastFaceDirection then
						BlockCFrame *= CFrame.lookAt(Vector3.zero, rayDirection.Unit)
					end

					pcall(function() -- Shapecast distance limit
						result = workspace:Blockcast (
							BlockCFrame,
							BlockSize or Vector3.zero,
							pos - point.LastPosition,
							RayParams
						) or RaycastOnShapecast and
							workspace:Raycast(point.LastPosition, pos - point.LastPosition, RayParams)
					end)
				end

				if Visualize then
					CreateAdornment(pos, point.LastPosition)
				end

				if result then
					OnHit:Fire(result, point.Attachment)
				end

				point.LastPosition = pos
			end
		end)
	end
end

function RaycastHitbox:EndHit()
	local HitConnection = self._HitConnection

	if HitConnection then
		HitConnection:Disconnect()
		self._HitConnection = nil
	end
end

return RaycastHitbox