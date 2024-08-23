local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local _GlobalToolsMeta = {
	__mode = "k", -- dont hold references to dead instances

	_AddTool = function(self, tool)
		self[tool.Instance] = tool
		self.OnToolAdded:Fire(tool)
	end,
	_RemoveTool = function(self, tool)
		if self[tool.Instance] then
			self[tool.Instance] = nil
			self.OnToolRemoved:Fire(tool)
		end
	end,

	OnToolAdded = Signal.new(),
	OnToolRemoved = Signal.new()
}
_GlobalToolsMeta.__index = _GlobalToolsMeta
local GlobalTools = setmetatable({}, _GlobalToolsMeta)

local Tool = {
	GlobalTools = GlobalTools,
	__type = "Tool"
}
Tool.__index = Tool

type ToolImpl = {
	__index: ToolImpl,
	__type: string,

	new: (ToolConfig) -> ToolObject,
	Init: (self: ToolObject) -> (),
	Destroy: (self: ToolObject) -> (),
	SetPlayer: (self: ToolObject, player: Player) -> ()
}

export type ToolConfig = {
	ToolName: string,
}

export type ToolObject = typeof(setmetatable({} :: ToolConfig & {
	Instance: Tool,

	ToolState: EnumState.EnumState,
	Equipped: boolean,

	OnEquipped: Signal.Signal<nil>,
	OnUnequipped: Signal.Signal<nil>,

	_DestroyingConnection: RBXScriptConnection?,
}, {} :: typeof(Tool)))

function Tool.new(config)
	local self = setmetatable(config, Tool)

	self.Equipped = false
	self.ToolState = EnumState.new(table.unpack(GameEnums.ToolState.OrderedItems))

	self.OnEquipped = Signal.new()
	self.OnUnequipped = Signal.new()

	if self.Instance then -- create guns by default on client
		self:Create()
	end

	return self
end

function Tool:Init()
	assert(self.Instance, "Attempt to create tool with no instance")
	Tool.GlobalTools:_AddTool(self)
	self._DestroyingConnection = self.Instance.Destroying:Connect(function() -- in case tool instance gets destroyed without object getting destroyed
		self:Destroy()
	end)
end

function Tool:Destroy()
	if self._DestroyingConnection then
		self._DestroyingConnection:Disconnect()
		self._DestroyingConnection = nil
	end
	if self.Instance then
		Tool.GlobalTools:_RemoveTool(self)
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