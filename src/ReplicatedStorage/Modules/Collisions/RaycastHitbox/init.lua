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
	local new = {
		Model = model,
		RaycastParams = rayParams
	}	
	new.OnHit = Signal.new()
	
	return setmetatable(new, RaycastHitbox)
end

local RAY_ENABLED = 1
local RAY_TYPE = 2
local ATTACHMENT = 3
local POSITION = 4
local LAST_POSITION = 5
local SIZE = 6
local RAY_ROTATION = 7

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
					rayEnabled,
					rayPointType,
					att,
					att.Position,
					att.WorldPosition, -- Last Position
					raySize or Vector3.zero, 
					rayOrientation and CFrame.fromOrientation(rayOrientation.X, rayOrientation.Y, rayOrientation.Z) or CFrame.identity
				})
			else
				table.insert(RayPointsTable, {
					att, 
					att.WorldPosition -- Last Position
				})
			end
		end
	end
	
	
	
	if not self.UpdateAttachments then
		self._HitConnection = RunService.Heartbeat:Connect(function(deltaTime)
			for _, point in ipairs(RayPointsTable) do
				local rayEnabled = point[RAY_ENABLED]
				rayEnabled = (rayEnabled == true or rayEnabled == nil)
				if not rayEnabled then continue end
				
				local partCFrame = point[ATTACHMENT].Parent.CFrame

				local pos = partCFrame.Position + point[POSITION]
				local lastPos = point[LAST_POSITION]
				
				local result = nil
				
				local rayPointType = point[RAY_TYPE]
				
				if rayPointType == RAY_CAST_NAME then
					result = workspace:Raycast(lastPos, pos - lastPos, RayParams)
					
				elseif rayPointType == SPHERE_CAST_NAME then
					pcall(function() -- Shapecast distance limit
						result = workspace:Spherecast(lastPos, point[SIZE], pos - lastPos, RayParams) 
							or RaycastOnShapecast and
							workspace:Raycast(lastPos, pos - lastPos, RayParams)
					end)
					
				elseif rayPointType == BLOCK_CAST_NAME then
					local BlockCFrame = CFrame.new(lastPos) * point[RAY_ROTATION]
					local rayDirection = pos - lastPos
					
					if BlockCastFaceDirection then
						BlockCFrame *= CFrame.lookAt(Vector3.zero, rayDirection.Unit)
					end
					
					pcall(function() -- Shapecast distance limit
						result = workspace:Blockcast (
							BlockCFrame, 
							point[SIZE],
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
					OnHit:Fire(result, point[ATTACHMENT])
				end
				
				point[LAST_POSITION] = pos
			end
		end)
	else
		self._HitConnection = RunService.Heartbeat:Connect(function(deltaTime)
			for _, attData in ipairs(RayPointsTable) do
				local att, lastPos = attData[1], attData[2]
				
				local rayEnabled = att:GetAttribute("RayEnabled")
				rayEnabled = (rayEnabled == true or rayEnabled == nil)
				if not rayEnabled then continue end
				
				local rayPointType = att:GetAttribute("RayPointType")
				
				local part = att.Parent
				local partCFrame = part.CFrame

				local pos = att.WorldPosition
				
				local result = nil
				
				if rayPointType == RAY_CAST_NAME then
					result = workspace:Raycast(pos, pos - lastPos, RayParams)
					
				elseif rayPointType == SPHERE_CAST_NAME then
					pcall(function() -- Shapecast distance limit
						result = workspace:Spherecast (
							pos, part:GetAttribute("RaySize") or 0, pos - lastPos, RayParams
						) or RaycastOnShapecast and
							workspace:Raycast(lastPos, pos - lastPos, RayParams)
					end)
					
				elseif rayPointType == BLOCK_CAST_NAME then
					local BlockSize = part:GetAttribute("RaySize") or Vector3.zero
					local BlockCFrame = part:GetAttribute("RayOrientation") or Vector3.zero
					
					local rayDirection = pos - lastPos
					
					BlockCFrame = CFrame.new(lastPos) * CFrame.fromOrientation(BlockCFrame.X, BlockCFrame.Y, BlockCFrame.Z)
					
					if BlockCastFaceDirection then
						BlockCFrame *= CFrame.lookAt(Vector3.zero, rayDirection.Unit)
					end
					
					pcall(function() -- Shapecast distance limit
						result = workspace:Blockcast (
							BlockCFrame, 
							BlockSize or Vector3.zero, 
							pos - lastPos, 
							RayParams
						) or RaycastOnShapecast and
							workspace:Raycast(lastPos, pos - lastPos, RayParams)
					end)
				end
				
				if Visualize then
					CreateAdornment(pos, lastPos)
				end
				
				if result then
					OnHit:Fire(result, att)
				end
				
				attData[2] = pos
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