local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolsList = require(ReplicatedStorage.Tools.ToolsList)
local PropertiesClass = require(ReplicatedStorage.Modules.General.PropertiesClass)
local Signal = require(ReplicatedStorage.Modules.General.GoodSignal)

local Tool = setmetatable({
	
}, PropertiesClass)

Tool.__index = Tool
Tool.__type = "Tool"

function Tool.new(new)
	new.OnEquipped = Signal.new()
	new.OnUnequipped = Signal.new()
	
	return setmetatable(PropertiesClass.new(new), Tool)
end

function Tool:Create()
	local ToolInstance = ReplicatedStorage.Tools:FindFirstChild(self.ToolName, true).Tool:Clone()
	ToolInstance.Name = self.ToolName
	
	ToolsList[ToolInstance] = self
	
	if self.Player then
		ToolInstance.Remotes.DataUpdate:FireClient(self.Player, self)
	end
	
	self.Instance = ToolInstance
	
	ToolInstance.Server.Enabled = true
	
	return ToolInstance
end

function Tool:Destroy()
	if self.Instance then self.Instance:Destroy() end
	
	ToolsList[self.Instance] = nil
end

function Tool:SetPlayer(player)
	self.Player = player
	
	if self.Instance then
		self.Instance.Remotes.DataUpdate:FireClient(player, self)
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