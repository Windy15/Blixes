local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local client = Players.LocalPlayer

local ActionBinder = require(ReplicatedStorage.Components.ActionBinder)
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
	Equip: (self: ToolObject) -> (),
	Unequip: (self: ToolObject) -> (),
	Destroy: (self: ToolObject) -> (),
	SetPlayer: (self: ToolObject, player: Player) -> ()
}

export type ToolConfig = {
	Instance: Tool,
}

export type ToolObject = ToolConfig & typeof(setmetatable({} ::  {
	ToolState: EnumState.EnumState,
	Equipped: boolean,

	Animations: {[string]: AnimationTrack},

	OnEquipped: Signal.Signal<>,
	OnUnequipped: Signal.Signal<>,

	ActionBinder: ActionBinder.ActionBinder,

	Cleaner: Cleaner.Cleaner,
}, {} :: ToolImpl))

function Tool.new(config)
	local self = setmetatable(config, Tool) :: ToolObject

	self.Equipped = false
	self.ToolState = EnumState.new(table.unpack(GameEnums.ToolState.OrderedItems))

	self.Animations = {}

	self.Cleaner = Cleaner.new()

	self.ActionBinder = self.Cleaner:AddObject(ActionBinder.new(self))

	self.OnEquipped = self.Cleaner:AddObject(Signal.new())
	self.OnUnequipped = self.Cleaner:AddObject(Signal.new())

	return self
end

function Tool:Init()
	assert(self.Instance, `Attempt to create tool {self.ToolName} with no instance`)
	self.Cleaner:AddObject(self.Instance.Destroying:Connect(function() -- in case tool instance gets destroyed without object getting destroyed
		self:Destroy()
	end))
	local toolFolder = ReplicatedStorage.Tools.Models:FindFirstChild(self.ToolName, true)
	assert(toolFolder, `Tool {self.ToolName} has no Models folder`)
	for _, animation in toolFolder.Animations:GetChildren() do
		local track = (client.Character or client.CharacterAdded:Wait()).Humanoid:WaitForChild("Animator"):LoadAnimation(animation)
		self.Animations[animation.Name] = track
		self.Cleaner:AddObject(track)
	end
end

function Tool:Destroy()
	self.Cleaner:Flush()
	if self.Instance then
		self.Instance:Destroy()
	end
end

function Tool:Equip()
	if self.Equipped or not self.ToolState:IsState(GameEnums.ToolState.Idle) then return end
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
	if not self.Equipped or not self.ToolState:IsState(GameEnums.ToolState.Idle) then return end

	self.Instance.Remotes.Unequip:FireServer()
	self.Equipped = false
end

return Tool