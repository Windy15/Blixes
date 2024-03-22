local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PropertiesClass = require(ReplicatedStorage.Modules.General.PropertiesClass)
local Signal = require(ReplicatedStorage.Modules.General.GoodSignal)

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

local Tool = setmetatable({
	
}, PropertiesClass)

Tool.__index = Tool
Tool.__type = "Tool"
Tool.GlobalTools = GlobalTools

function Tool.new(new)
	new.OnEquipped = Signal.new()
	new.OnUnequipped = Signal.new()
	
	return setmetatable(PropertiesClass.new(new), Tool)
end

function Tool:Create()
	local ToolInstance = ReplicatedStorage.Tools:FindFirstChild(self.ToolName, true).Tool:Clone()
	ToolInstance.Name = self.ToolName
	
	if self.Player then
		self:SetPlayer(self.Player)
	end
	
	self.Instance = ToolInstance
	GlobalTools[self.Instance] = self
	GlobalTools.OnToolAdded:Fire(self)

	ToolInstance.Server.Enabled = true
	
	return ToolInstance
end

function Tool:Destroy()
	if self.Instance then self.Instance:Destroy() end
	GlobalTools[self.Instance] = nil
	GlobalTools.OnToolRemoved:Fire(self)
end

function Tool:SetPlayer(player)
	self.Player = player
	
	if self.Instance then
		self.Instance.Remotes.ReplicateObject:FireClient(player, self)
	end
	
	if self.Parent ~= player.Backpack and self.Parent ~= player.Character then
		self.Parent = player.Backpack
	end
end

function Tool:Equip()
	if self.Equipped then return end

	self.Instance.Parent = self.Character
	self.Equipped = true
end

function Tool:Unequip()
	if not self.Equipped then return end

	self.Instance.Parent = self.Player.Backpack
	self.Equipped = false
end

return Tool