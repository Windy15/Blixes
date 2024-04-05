local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PropertiesClass = require(ReplicatedStorage.Modules.General.PropertiesClass)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local ListMeta = {
	OnToolAdded = Signal.new(),
	OnToolRemoved = Signal.new()
}
ListMeta.__index = ListMeta
ListMeta.__len = function(self)
    local total = 0

    for _ in pairs(self) do
        total += 1
    end

    return total
end
local GlobalTools = setmetatable({}, ListMeta)

local Tool = {
	GlobalTools = GlobalTools,
	__type = "Tool"
}
Tool.__index = Tool

function Tool.new(config)
	local new = setmetatable(PropertiesClass.new(config), Tool)

	new.OnEquipped = Signal.new()
	new.OnUnequipped = Signal.new()

	return new
end

function Tool:Create()
	local toolFolder = ReplicatedStorage.Tools:FindFirstChild(self.ToolName, true)
	assert(toolFolder, string.format("'%s' is not a valid ToolName", self.ToolName))
	local toolClone = toolFolder.Tool:Clone()

	toolClone.Name = self.Name

	if self.Player then
		self:SetPlayer(self.Player)
	end

	self.Instance = toolClone
	GlobalTools[self.Instance] = self
	GlobalTools.OnToolAdded:Fire(self)

	toolClone.Server.Enabled = true

	return toolClone
end

function Tool:Destroy()
	if self.Instance then self.Instance:Destroy() end
	GlobalTools[self.Instance] = nil
	GlobalTools.OnToolRemoved:Fire(self)
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