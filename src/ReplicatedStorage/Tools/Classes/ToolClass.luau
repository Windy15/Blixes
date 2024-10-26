local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local client = Players.LocalPlayer

local ClientScripts = client.PlayerScripts

local ActionBinder = require(ClientScripts.Components.ActionBinder)
local Cleaner = require(ReplicatedStorage.Modules.General.Cleaner)
local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local ToolRemotes = ReplicatedStorage.Remotes.Tools

local Tool = {
	__type = "Tool",
	ToolName = "None",
} :: ToolImpl
Tool.__index = Tool

type ToolImpl = {
	__index: ToolImpl,
	__type: string,
	ToolName: "None",

	new: (config: ToolConfig) -> ToolObject,
	Init: (self: ToolObject) -> (),
	Equip: (self: ToolObject) -> (),
	Unequip: (self: ToolObject) -> (),
	Destroy: (self: ToolObject) -> (),
	SetPlayer: (self: ToolObject, player: Player) -> ()
}

export type ToolConfig = {
	ToolName: string,
	Instance: Tool,
}

export type ToolObject = ToolConfig & typeof(setmetatable({} ::  {
	ToolState: EnumState.EnumState,
	Equipped: boolean,

	Actions: {[string]: any},
	Animations: {[string]: AnimationTrack},

	OnInitialized: Signal.Signal<>,
	OnEquipped: Signal.Signal<>,
	OnUnequipped: Signal.Signal<>,

	ActionBinder: ActionBinder.ActionBinder,

	Cleaner: Cleaner.Cleaner,
}, {} :: ToolImpl))

function Tool.new(config)
	local self = setmetatable(config, Tool) :: ToolObject

	self.Equipped = false
	self.ToolState = EnumState.new(table.unpack(GameEnums.ToolState.OrderedItems))

	self.Actions = {}
	self.Animations = {}

	self.Cleaner = Cleaner.new()

	self.ActionBinder = self.Cleaner:AddObject(ActionBinder.new(self))

	self.OnInitialized = self.Cleaner:AddObject(Signal.new())
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

	self.OnInitialized:Fire()
	self.OnInitialized:Destroy()
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

	ToolRemotes.Equip:FireServer()
	self.Instance.Parent = self.Character
	self.Equipped = true

	local equipAnim = self.Player.Character:LoadAnimation(self.Animations.EquipAnimation)
	self.CurrentAnim = equipAnim
	equipAnim:Play()
	self.Cleaner:AddObject(equipAnim.Ended:Once(function()
		self.ToolState:SetState(GameEnums.ToolState.Idle)
	end))
end

function Tool:Unequip()
	if not self.Equipped or not self.ToolState:IsState(GameEnums.ToolState.Idle) then return end

	ToolRemotes.Unequip:FireServer()
	self.Equipped = false
end

return Tool