local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cleaner = require(ReplicatedStorage.Modules.General.Cleaner)
local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local _GlobalToolsMeta = {
	__mode = "k", -- dont hold references to destroyed instances

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
	__type = "Tool",
	ToolName = "DefaultTool",
} :: ToolImpl
Tool.__index = Tool

export type ToolImpl = {
	__index: ToolImpl,
	__type: string,
	ToolName: string,

	GlobalTools: typeof(GlobalTools),

	new: (config: ToolConfig) -> ToolObject,
	Init: (self: ToolObject) -> (),
	Destroy: (self: ToolObject) -> (),
	GetReplicateConfig: (self: ToolObject) -> any,
	SetPlayer: (self: ToolObject, player: Player) -> (),
}

export type ToolConfig = {}

export type ToolObject = ToolConfig & typeof(setmetatable({} :: {
	Instance: Tool,
	Player: Player,

	Equipped: boolean,
	ToolState: EnumState.EnumState,
	Cooldowns: {[string]: any},

	OnEquipped: Signal.Signal<nil>,
	OnUnequipped: Signal.Signal<nil>,

	Cleaner: Cleaner.Cleaner,
}, {} :: ToolImpl))

function Tool.new(config: ToolConfig)
	local self = setmetatable(config, Tool) :: ToolObject

	self.Equipped = false
	self.ToolState = EnumState.new(table.unpack(GameEnums.ToolState.OrderedItems))

	self.Cleaner = Cleaner.new()

	self.OnEquipped = Signal.new()
	self.OnUnequipped = self.Cleaner:AddObject(Signal.new())

	return self
end

function Tool:Init()
	local toolFolder = ReplicatedStorage.Tools:FindFirstChild(self.ToolName, true)
	if not toolFolder then
		error(`'{self.ToolName}' is not a valid ToolName, or has no tool model`, 2)
	end
	local toolClone = toolFolder.Tool:Clone()

	toolClone.Name = self.ToolName

	if self.Player then
		self:SetPlayer(self.Player)
	end

	self.Instance = toolClone
	Tool.GlobalTools:_AddTool(self)

	self.Cleaner:AddObject(toolClone.Destroying:Connect(function() -- in case tool instance gets destroyed without object getting destroyed
		warn(`Tool instance {self.ToolName} destroyed without calling :Destroy() on object`)
		self:Destroy()
	end))

	toolClone.Server.Enabled = true

	return toolClone
end

function Tool:Destroy()
	self.Cleaner:Finish()
	if self.Instance then self.Instance:Destroy() end
	Tool.GlobalTools:_RemoveTool(self)
end

function Tool:GetReplicateConfig()
	return {}
end

function Tool:SetPlayer(player)
	self.Player = player

	if player then
		if self.Instance then
			self.Instance.ReplicateObject:FireClient(player, self.ToolName, self:GetReplicateConfig())
		end

		if self.Instance.Parent ~= player.Backpack and self.Instance.Parent ~= player.Character then
			self.Instance.Parent = player.Backpack
		end
	else
		self.Instance.Parent = nil
	end
end

return Tool