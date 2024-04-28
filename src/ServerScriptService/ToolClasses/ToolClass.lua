local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ListClass = require(ReplicatedStorage.Modules.General.ListClass)
local PropertiesClass = require(ReplicatedStorage.Modules.General.PropertiesClass)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local Tool = {
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
}
Tool.__index = Tool

function Tool.new(config)
	local new = setmetatable(PropertiesClass.new(config), Tool)

	new.OnEquipped = Signal.new()
	new.OnUnequipped = Signal.new()

	return new
end

local destroyingConnection = nil -- in case tool instance gets destroyed without object getting destroyed

function Tool:Create()
	local toolFolder = ReplicatedStorage.Tools:FindFirstChild(self.ToolName, true)
	assert(toolFolder, string.format("'%s' is not a valid ToolName", self.ToolName))
	local toolClone = toolFolder.Tool:Clone()

	toolClone.Name = self.Name

	if self.Player then
		self:SetPlayer(self.Player)
	end

	self.Instance = toolClone
	Tool.GlobalTools:AddTool(self)

	destroyingConnection = toolClone.Destroying:Connect(function()
		self:Destroy()
	end)

	toolClone.Server.Enabled = true

	return toolClone
end

function Tool:Destroy()
	if destroyingConnection then
		destroyingConnection:Disconnect()
		destroyingConnection = nil
	end
	if self.Instance then self.Instance:Destroy() end
	Tool.GlobalTools:RemoveTool(self)
end

function Tool:SetPlayer(player)
	self.Player = player

	if player then
		if self.Instance then
			self.Instance.Remotes.ReplicateObject:FireClient(player, self)
		end

		if self.Instance.Parent ~= player.Backpack and self.Instance.Parent ~= player.Character then
			self.Instance.Parent = player.Backpack
		end
	else
		self.Instance.Parent = nil
	end
end

return Tool