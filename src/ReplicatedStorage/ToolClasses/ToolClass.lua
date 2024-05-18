local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEnums = require(ReplicatedStorage.GameEnums)
local ListClass = require(ReplicatedStorage.Modules.General.ListClass)
local PropertiesClass = require(ReplicatedStorage.Modules.General.PropertiesClass)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local Tool = setmetatable({
	GlobalTools = ListClass.new({}, {
		OnToolAdded = Signal.new(),
		OnToolRemoved = Signal.new(),
		AddTool = function(self, tool)
			self[tool.Instance] = tool
			self.OnToolAdded:Fire(tool)
		end,
		RemoveTool = function(self, tool)
			if self[tool.Instance] then
				self[tool.Instance] = nil
				self.OnToolRemoved:Fire(tool)
			end
		end,
	}),
	__type = "Tool"
}, PropertiesClass)
Tool.__index = Tool

function Tool.new(config)
	local new = setmetatable(PropertiesClass.new(config), Tool)

	new.ToolState = config.ToolState or GameEnums.ToolState.Idle
	new.OnEquipped = Signal.new()
	new.OnUnequipped = Signal.new()

	if new.Instance then -- create guns by default on client
		new:Create()
	end

	return new
end

local destroyingConnection = nil -- in case tool instance gets destroyed without object getting destroyed

function Tool:Create()
	assert(self.Instance, "Attempt to create tool with no instance")
	Tool.GlobalTools:AddTool(self)
	destroyingConnection = self.Instance.Destroying:Connect(function()
		self:Destroy()
	end)
end

function Tool:Destroy()
	if destroyingConnection then
		destroyingConnection:Disconnect()
		destroyingConnection = nil
	end
	if self.Instance then
		Tool.GlobalTools:RemoveTool(self)
		self.Instance:Destroy()
	end
end

function Tool:Equip()
	if self.Equipped then return end

	self.Instance.Remotes.Equip:FireServer()
	self.Instance.Parent = self.Character
	self.Equipped = true

	local equipAnim = self.Player.Character:LoadAnimation(self.Instance.Animations.EquipAnimation)
	self.CurrentAnim = equipAnim
	equipAnim:Play()
end

function Tool:Unequip()
	if not self.Equipped then return end

	self.Instance.Remotes.Unequip:FireServer()
	self.Instance.Parent = self.Player.Backpack
	self.Equipped = false
end

return Tool