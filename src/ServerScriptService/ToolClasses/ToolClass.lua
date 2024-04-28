local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ListClass = require(ReplicatedStorage.Modules.General.ListClass)
local PropertiesClass = require(ReplicatedStorage.Modules.General.PropertiesClass)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local Tool = {
	GlobalTools = ListClass.new({}, {
		OnToolAdded = Signal.new(),
		OnToolRemoved = Signal.new()
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
	Tool.GlobalTools[self.Instance] = self
	Tool.GlobalTools.OnToolAdded:Fire(self)

	destroyingConnection = toolClone.Destroying:Connect(function()
		self:Destroy()
	end)

	toolClone.Server.Enabled = true

	return toolClone
end

function Tool:Destroy()
	if self.Instance then self.Instance:Destroy() end
	if destroyingConnection then
		destroyingConnection:Disconnect()
		destroyingConnection = nil
	end
	Tool.GlobalTools[self.Instance] = nil
	Tool.GlobalTools.OnToolRemoved:Fire(self)
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