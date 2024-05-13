--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local RAY_CAST_NAME = "Line"
local SPHERE_CAST_NAME = "Sphere"
local BLOCK_CAST_NAME = "Block"

local RaycastHitbox = {}
RaycastHitbox.__index = RaycastHitbox

function RaycastHitbox.new(model: Instance, rayParams: RaycastParams?, hitOnce: boolean?, humanoidOnly: boolean?)
	local new = setmetatable({
		Model = model,
		RaycastParams = rayParams or RaycastParams.new(),
		RayPointName = nil, -- Name of the attachments that will be a part of the hitbox (optional)
		HitOnce = hitOnce, Hits = {}, -- If the OnHit should only fire a hit for each part once, and the table which contains already hit parts
		HumanoidOnly = humanoidOnly, -- Only fires OnHit when in contact with a part whos model ancestor has a humanoid

		Visualize = false, -- Debug visualizer
		RaycastOnShapecast = true, -- Whether to raycast normally for every shapecast to deal with the shapecast limitations
		UpdateAttachments = false, -- If properties or attributes of attachments updating should be taken into account (slower)
		ShallowAttachments = false, -- Whether to only get children and not descendents of "Model"

		BlockCastFaceDirection = true, -- If BlockCasting faces the direction it goes

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

	local RayPointsTable = {}
	local Hits = {}
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
		self._HitConnection = RunService.PostSimulation:Connect(function()
			for _, point in ipairs(RayPointsTable) do
				local rayEnabled = point.RayEnabled
				rayEnabled = (rayEnabled == true or rayEnabled == nil)
				if not rayEnabled then continue end

				local partCFrame = point.Attachment.Parent.CFrame
				local pos = partCFrame.Position + point.Position
				local lastPos = point.LastPosition

				local result = nil

				if point.RayPointType == RAY_CAST_NAME then
					result = workspace:Raycast(lastPos, pos - lastPos, self.RayParams)
				elseif point.RayPointType == SPHERE_CAST_NAME then
					pcall(function() -- Shapecast distance limit
						result = workspace:Spherecast(lastPos, point.RaySize, pos - lastPos, self.RayParams)
							or self.RaycastOnShapecast and
							workspace:Raycast(lastPos, pos - lastPos, self.RayParams)
					end)
				elseif point.RayPointType == BLOCK_CAST_NAME then
					local BlockCFrame = CFrame.new(lastPos) * point.RayOrientation
					local rayDirection = pos - lastPos

					if self.BlockCastFaceDirection then
						BlockCFrame *= CFrame.lookAt(Vector3.zero, rayDirection.Unit)
					end

					pcall(function() -- Shapecast distance limit
						result = workspace:Blockcast (
							BlockCFrame,
							point.RaySize,
							rayDirection,
							self.RayParams
						) or self.RaycastOnShapecast and
							workspace:Raycast(lastPos, pos - lastPos, self.RayParams)
					end)
				end

				if self.Visualize then
					CreateAdornment(pos, lastPos)
				end

				if result and not (self.HitOnce and table.find(Hits, result.Instance)) then
					table.insert(Hits, result.Instance)
					if self.HumanoidOnly then
						local model = result.Instance:FindFirstAncestorWhichIsA("Model")
						if model then
							local humanoid = model:FindFirstChildWhichIsA("Humanoid")
							if humanoid then
								self.OnHit:Fire(result, point.Attachment, humanoid)
							end
						end
					else
						self.OnHit:Fire(result, point.Attachment)
					end
				end

				point.LastPosition = pos
			end
		end)
	else
		self._HitConnection = RunService.PostSimulation:Connect(function()
			for _, point in ipairs(RayPointsTable) do
				local rayEnabled = point.Attachment:GetAttribute("RayEnabled")
				rayEnabled = (rayEnabled == true or rayEnabled == nil)
				if not rayEnabled then continue end

				local rayPointType = point.Attachment:GetAttribute("RayPointType")
				local part = point.Attachment.Parent
				local pos = point.Attachment.WorldPosition

				local result = nil

				if rayPointType == RAY_CAST_NAME then
					result = workspace:Raycast(pos, pos - point.LastPosition, self.RayParams)
				elseif rayPointType == SPHERE_CAST_NAME then
					pcall(function() -- Shapecast distance limit
						result = workspace:Spherecast (
							pos, part:GetAttribute("RaySize") or 0, pos - point.LastPosition, self.RayParams
						) or self.RaycastOnShapecast and
							workspace:Raycast(point.LastPosition, pos - point.LastPosition, self.RayParams)
					end)
				elseif rayPointType == BLOCK_CAST_NAME then
					local BlockSize = part:GetAttribute("RaySize") or Vector3.zero
					local BlockCFrame = part:GetAttribute("RayOrientation") or Vector3.zero
					local rayDirection = pos - point.LastPosition

					BlockCFrame = CFrame.new(point.LastPosition) * CFrame.fromOrientation(BlockCFrame.X, BlockCFrame.Y, BlockCFrame.Z)

					if self.BlockCastFaceDirection then
						BlockCFrame *= CFrame.lookAt(Vector3.zero, rayDirection.Unit)
					end

					pcall(function() -- Shapecast distance limit
						result = workspace:Blockcast (
							BlockCFrame,
							BlockSize or Vector3.zero,
							pos - point.LastPosition,
							self.RayParams
						) or self.RaycastOnShapecast and
							workspace:Raycast(point.LastPosition, pos - point.LastPosition, self.RayParams)
					end)
				end

				if self.Visualize then
					CreateAdornment(pos, point.LastPosition)
				end

				if result and not (self.HitOnce and table.find(Hits, result.Instance)) then
					table.insert(Hits, result.Instance)
					if self.HumanoidOnly then
						local model = result.Instance:FindFirstAncestorWhichIsA("Model")
						if model then
							local humanoid = model:FindFirstChildWhichIsA("Humanoid")
							if humanoid then
								self.OnHit:Fire(result, point.Attachment, humanoid)
							end
						end
					else
						self.OnHit:Fire(result, point.Attachment)
					end
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