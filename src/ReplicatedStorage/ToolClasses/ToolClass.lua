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

	if new.Instance then
		Tool.GlobalTools[new.Instance] = new
	end

	return new
end

function Tool:Destroy()
	if self.Instance then
		Tool.GlobalTools[self.Instance] = nil
		self.Instance:Destroy()
	end
end

function Tool:Equip()
	if self.Equipped then return end

	self.Instance.Remotes.Equipped:FireServer()
	self.Instance.Parent = self.Character
	self.Equipped = true

	local equipAnim = self.Player.Character:LoadAnimation(self.Instance.Animations.EquipAnimation)
	self.CurrentAnim = equipAnim
	equipAnim:Play()
end

function Tool:Unequip()
	if not self.Equipped then return end

	self.Instance.Remotes.Unequipped:FireServer()
	self.Instance.Parent = self.Player.Backpack
	self.Equipped = false
end

return Tool