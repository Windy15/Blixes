--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Cleaner = require(ReplicatedStorage.Modules.General.Cleaner)
local EnumState = require(ReplicatedStorage.Modules.General.EnumState)
local GameEnums = require(ReplicatedStorage.GameEnums)
local GlobalObjects = require(ServerScriptService.GlobalObjects)
local Modifier = require(ReplicatedStorage.Components.Modifier)
local Replicator = require(ServerScriptService.Components.Replicator)
local Signal = require(ReplicatedStorage.Modules.General.Signal)

local ToolRemotes = ReplicatedStorage.Remotes.Tools

local Tool = {
	__type = "Tool",
	ToolName = "None",
} :: ToolImpl
Tool.__index = Tool

export type ToolImpl = {
	__index: ToolImpl,
	ToolName: "None",
	__type: "Tool",

	new: (config: ToolConfig) -> ToolObject,
	Init: (self: ToolObject, config: InitConfig) -> (),
	SetValue: (self: ToolObject, name: string, value: any) -> (),
	Destroy: (self: ToolObject) -> (),
	GetReplicateConfig: (self: ToolObject) -> any,
	SetPlayer: (self: ToolObject, player: Player) -> (),
}

export type ToolConfig = {
	
}

export type ToolObject = ToolConfig & typeof(setmetatable({} :: {
	Instance: Tool,
	Player: Player,

	Equipped: boolean,
	ToolState: EnumState.EnumState,

	Actions: {[string]: any},

	DisplayName: string,

	Modifier: Modifier.Modifier,
	Replicator: Replicator.Replicator,

	Cleaner: Cleaner.Cleaner,

	OnInitialized: Signal.Signal<>,
	OnEquipped: Signal.Signal<>,
	OnUnequipped: Signal.Signal<>,

	_Initialized: boolean,
}, {} :: ToolImpl))

type InitConfig = {

}

function Tool.new(config: ToolConfig)
	local self = setmetatable(config, Tool) :: ToolObject

	self._Initialized = false

	self.Equipped = false
	self.ToolState = EnumState.new(table.unpack(GameEnums.ToolState.OrderedItems))

	self.Actions = {}

	self.DisplayName = "Default Tool"

	self.Cleaner = Cleaner.new()

	self.Modifier = self.Cleaner:AddObject(Modifier.new(self))
	self.Replicator = self.Cleaner:AddObject(Replicator.new(self, ToolRemotes.ChangeValue))

	self.OnInitialized = self.Cleaner:AddObject(Signal.new())
	self.OnEquipped = self.Cleaner:AddObject(Signal.new())
	self.OnUnequipped = self.Cleaner:AddObject(Signal.new())

	return self
end

function Tool:Init(config)
	local toolFolder = ReplicatedStorage.Tools:FindFirstChild(self.ToolName, true)
	if not toolFolder then
		error(`'{self.ToolName}' is not a valid ToolName, or has no tool model`, 2)
	end
	local toolClone = toolFolder.Tool:Clone()

	toolClone.Name = self.DisplayName

	if self.Player then
		self:SetPlayer(self.Player)
	end

	self.Instance = toolClone
	GlobalObjects.Storages.Tools:AddObject(self.Instance, self)

	self.Cleaner:AddObject(toolClone.Destroying:Connect(function() -- in case tool instance gets destroyed without object getting destroyed
		warn(`Tool instance {self.ToolName} destroyed without calling :Destroy() on object`)
		self:Destroy()
	end))

	self._Initialized = true

	self.OnInitialized:Fire()
	self.OnInitialized:Destroy()

	return toolClone
end

function Tool:SetValue(property: string, value: any)
	self[property] = value
	self.Replicator:Replicate(property, value)
end

function Tool:GetReplicateConfig()
	return {}
end

function Tool:SetPlayer(player)
	self.Player = player

	if player then
		if self.Instance then
			ToolRemotes.ReplicateConfig:FireClient(player, self.ToolName, self:GetReplicateConfig())
		end

		self.Replicator.PlayersToReplicate[player] = true
	else
		self.Instance.Parent = nil
	end
end

function Tool:Destroy()
	self.Cleaner:Flush()
	if self.Instance then self.Instance:Destroy() end
	GlobalObjects.Storages.Tools:RemoveObject(self.Instance)
end

return Tool