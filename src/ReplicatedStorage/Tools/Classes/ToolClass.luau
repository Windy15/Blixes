local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cleaner = require(ReplicatedStorage.Modules.General.Cleaner)
local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local Tool = {
	__type = "Tool",
	ToolName = "DefaultTool",
} :: ToolImpl
Tool.__index = Tool

type ToolImpl = {
	__index: ToolImpl,
	__type: string,
	ToolName: string,

	new: (config: ToolConfig) -> ToolObject,
	Init: (self: ToolObject) -> (),
	Destroy: (self: ToolObject) -> (),
	SetPlayer: (self: ToolObject, player: Player) -> ()
}

export type ToolConfig = {}

export type ToolObject = typeof(setmetatable({} :: ToolConfig & {
	Instance: Tool,

	ToolState: EnumState.EnumState,
	Equipped: boolean,

	OnEquipped: Signal.Signal<nil>,
	OnUnequipped: Signal.Signal<nil>,

	Cleaner: Cleaner.Cleaner,
}, {} :: ToolImpl))

function Tool.new(config)
	local self = setmetatable(config, Tool)

	self.Equipped = false
	self.ToolState = EnumState.new(table.unpack(GameEnums.ToolState.OrderedItems))

	self.Cleaner = Cleaner.new()

	self.OnEquipped = self.Cleaner:AddObject(Signal.new())
	self.OnUnequipped = self.Cleaner:AddObject(Signal.new())

	if self.Instance then -- create guns by default on client
		self:Create()
	end

	return self
end

function Tool:Init()
	assert(self.Instance, "Attempt to create tool with no instance")
	self.Cleaner:AddObject(self.Instance.Destroying:Connect(function() -- in case tool instance gets destroyed without object getting destroyed
		self:Destroy()
	end))
end

function Tool:Destroy()
	self.Cleaner:Finish()
	if self.Instance then
		self.Instance:Destroy()
	end
end

function Tool:Equip()
	if self.Equipped or self.ToolState:GetState(GameEnums.ToolState.Idle) then return end
	self.ToolState:SetState(GameEnums.ToolState.Equipping)

	self.Instance.Remotes.Equip:FireServer()
	self.Instance.Parent = self.Character
	self.Equipped = true

	local equipAnim = self.Player.Character:LoadAnimation(self.Instance.Animations.EquipAnimation)
	self.CurrentAnim = equipAnim
	equipAnim:Play()
	equipAnim.Ended:Once(function()
		self.ToolState:SetState(GameEnums.ToolState.Idle)
	end)
end

function Tool:Unequip()
	if not self.Equipped or self.ToolState:GetState(GameEnums.ToolState.Idle)  then return end

	self.Instance.Remotes.Unequip:FireServer()
	self.Instance.Parent = self.Player.Backpack
	self.Equipped = false
end

return Tool