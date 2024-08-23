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

	Equipped: boolean,
	ToolState: EnumState.EnumState,
	Cooldowns: {[string]: any},

	OnEquipped: Signal.Signal<nil>,
	OnUnequipped: Signal.Signal<nil>,

	_DestroyingConnection: RBXScriptConnection?,
}, {} :: ToolImpl))

function Tool.new(config: ToolConfig)
	local self = setmetatable(config, Tool)

	self.Equipped = false
	self.ToolState = EnumState.new(table.unpack(GameEnums.ToolState.OrderedItems))

	self.OnEquipped = Signal.new()
	self.OnUnequipped = Signal.new()

	return self
end

function Tool:Init()
	local toolFolder = ReplicatedStorage.Tools:FindFirstChild(self.ToolName, true)
	if not toolFolder then
		error(`'{self.ToolName}' is not a valid ToolName, or has no tool model`, 2)
	end
	local toolClone = toolFolder.Tool:Clone()

	toolClone.Name = self.Name

	if self.Player then
		self:SetPlayer(self.Player)
	end

	self.Instance = toolClone
	Tool.GlobalTools:_AddTool(self)

	self._DestroyingConnection = toolClone.Destroying:Connect(function() -- in case tool instance gets destroyed without object getting destroyed
		warn(`Tool instance {self.ToolName} destroyed without calling :Destroy() on object`)
		self:Destroy()
	end)

	toolClone.Server.Enabled = true

	return toolClone
end

function Tool:Destroy()
	if self._DestroyingConnection then
		self._DestroyingConnection:Disconnect()
		self._DestroyingConnection = nil
	end
	if self.Instance then self.Instance:Destroy() end
	Tool.GlobalTools:_RemoveTool(self)
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