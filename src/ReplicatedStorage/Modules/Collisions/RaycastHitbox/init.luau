--!native
--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local DEFAULT_RAY_POINT_NAME = "HitPoint"

local RAY_CAST_NAME = "Line"
local SPHERE_CAST_NAME = "Sphere"
local BLOCK_CAST_NAME = "Block"

local RaycastHitbox = {} :: RaycastHitboxImpl
RaycastHitbox.__index = RaycastHitbox

type RaycastHitboxImpl = {
	__index: RaycastHitboxImpl,

	new: (model: Instance, rayParams: RaycastParams?, hitOnce: boolean?, humanoidOnly: boolean?) -> RaycastHitbox,
	StartHit: (self: RaycastHitbox) -> (),
	EndHit: (self: RaycastHitbox) -> (),
}

export type RaycastHitbox = typeof(setmetatable({} ::{
	Model: Instance,
	RaycastParams: RaycastParams,
	HitOnce: boolean,
	HumanoidOnly: boolean,

	RayPointName: string,
	Visualize: boolean,
	RaycastOnShapecast: boolean,
	UpdateAttributes: boolean,
	ShallowAttachments: boolean,

	BlockCastFaceDirection: boolean,

	OnHit: Signal.Signal,

	_HitConnection: RBXScriptConnection?,
}, {} :: RaycastHitboxImpl))

function RaycastHitbox.new(model: Instance, rayParams: RaycastParams?, hitOnce: boolean?, humanoidOnly: boolean?): RaycastHitbox
	local new = setmetatable({
		Model = model,
		RaycastParams = rayParams or RaycastParams.new(),
		HitOnce = hitOnce or false, -- If the OnHit should only fire a hit for each part once, and the table which contains already hit parts
		HumanoidOnly = humanoidOnly or false, -- Only fires OnHit when in contact with a part whos model ancestor has a humanoid

		RayPointName = DEFAULT_RAY_POINT_NAME, -- the names of the attachments which will be turned into ray points
		Visualize = false, -- Debug visualizer
		RaycastOnShapecast = true, -- Combines regular raycasting with shapecasts to deal with the shapecast limitations
		UpdateAttributes = false, -- If true properties and attributes of ray points don't get cached and will update (could affect performance)
		ShallowAttachments = false, -- Whether to only get children and not descendents of "Model"

		BlockCastFaceDirection = true, -- If BlockCasting faces the direction it goes (takes RayOrientation attribute into account aswell)

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

	task.delay(3, function()
		adornment:Destroy()
	end)
end

function RaycastHitbox:StartHit()
	if not self.Model then
		error("RaycastHitbox object must have a \"Model\" before :StartHit()", 2)
	end
	if self._HitConnection then return end

	local RayPointsTable = {} :: {any}
	local attachments = self.ShallowAttachments and self.Model:GetChildren() or self.Model:GetDescendants()

	for _, att in ipairs(attachments) do
		if att.Name ~= self.RayPointName then continue end

		if att:IsA("Attachment") then
			if not self.UpdateAttributes then
				local rayEnabled = att:GetAttribute("RayEnabled")
				rayEnabled = rayEnabled ~= false

				local raySize, rayOrientation = att:GetAttribute("RaySize"), att:GetAttribute("RayOrientation")

				table.insert(RayPointsTable, {
					RayEnabled = rayEnabled,
					RayPointType = att:GetAttribute("RayPointType") or RAY_CAST_NAME,
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

	self._HitConnection = RunService.PostSimulation:Connect(function()
		for _, point in ipairs(RayPointsTable) do
			local rayEnabled = (self.UpdateAttributes and point.Attachment:GetAttribute("RayEnabled") or point.RayEnabled)
			rayEnabled = rayEnabled ~= false
			if not rayEnabled then continue end

			local rayPointType
			local raySize
			local rayOrientation
			local pos

			if self.UpdateAttributes then
				rayPointType = point.Attachment:GetAttribute("RayPointType")
				raySize = point.Attachment:GetAttribute("RaySize")
				rayOrientation = point.Attachment:GetAttribute("RayOrientation")
				pos = point.Attachment.WorldPosition
			else
				rayPointType = point.RayPointType
				raySize = point.RaySize
				rayOrientation = point.RayOrientation
				local partCFrame = point.Attachment.Parent.CFrame
				pos = partCFrame.Position + point.Position
			end

			local lastPos = point.LastPosition

			local result = nil

			if rayPointType == RAY_CAST_NAME then
				result = workspace:Raycast(lastPos, pos - lastPos, self.RaycastParams)
			elseif rayPointType == SPHERE_CAST_NAME then
				pcall(function() -- Shapecast distance limit
					result = workspace:Spherecast(lastPos, raySize, pos - lastPos, self.RaycastParams)
						or self.RaycastOnShapecast and
						workspace:Raycast(lastPos, pos - lastPos, self.RaycastParams)
				end)
			elseif rayPointType == BLOCK_CAST_NAME then
				local BlockCFrame = CFrame.new(lastPos) * rayOrientation
				local rayDirection = pos - lastPos

				if self.BlockCastFaceDirection then
					BlockCFrame *= CFrame.lookAt(Vector3.zero, rayDirection.Unit)
				end

				pcall(function() -- Shapecast distance limit
					result = workspace:Blockcast (
						BlockCFrame,
						raySize,
						rayDirection,
						self.RaycastParams
					) or self.RaycastOnShapecast and
						workspace:Raycast(lastPos, pos - lastPos, self.RaycastParams)
				end)
			end

			if self.Visualize then
				CreateAdornment(pos, lastPos)
			end

			if result then
				if self.HitOnce then
					local filter = self.RaycastParams.FilterType
					if filter == Enum.RaycastFilterType.Exclude then
						self.RaycastParams:AddToFilter(result.Instance)
					elseif filter == Enum.RaycastFilterType.Include then
						local filterTable = self.RaycastParams.FilterDescendantsInstances
						local index = table.find(filterTable, result.Instance)
						if index then
							table.remove(filterTable, index)
							self.RaycastParams.FilterDescendantsInstances = filterTable
						end
					else
						warn(`Unknown RaycastFilterType for RaycastHitbox {self} with model {self.Model}`)
					end
				end

				if self.HumanoidOnly then
					local model = result.Instance:FindFirstAncestorWhichIsA("Model")
					local humanoid = model and model:FindFirstChildWhichIsA("Humanoid")
					if humanoid then
						self.OnHit:Fire(result, point.Attachment, humanoid)
					end
				else
					self.OnHit:Fire(result, point.Attachment)
				end
			end

			point.LastPosition = pos
		end
	end)
end

function RaycastHitbox:EndHit()
	local HitConnection = self._HitConnection
	if HitConnection then
		HitConnection:Disconnect()
		self._HitConnection = nil
	end
end

return RaycastHitbox