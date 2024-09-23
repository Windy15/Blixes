--!strict

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ServerScriptService.Components.Types)

local GlobalReplicators = setmetatable({} :: {[Replicator]: boolean}, {__mode = "k"})

type ReplicatorImpl = {
    __index: ReplicatorImpl,

    new: (holder: Types.Holder, changeRemote: RemoteEvent | UnreliableRemoteEvent, properties: {string}?) -> Replicator,
    Replicate: (self: Replicator, key: string, replacement: {Value: any}?) -> (),

    Destroy: (self: Replicator) -> (),
}

export type Replicator = typeof(setmetatable({} :: {
    Holder: Types.Holder,
    _ChangeRemote: RemoteEvent | UnreliableRemoteEvent,
    ReplicatingQueue: {[string]: {Value: any}},
    PlayersToReplicate: {[Player]: boolean},
    PropertiesToReplicate: {string},
}, {} :: ReplicatorImpl))

local Replicator = {} :: ReplicatorImpl
Replicator.__index = Replicator

function Replicator.new(holder, changeRemote, properties)
    local self = setmetatable({
        Holder = holder,
        _ChangeRemote = changeRemote,
        ReplicatingQueue = {},
        PlayersToReplicate = {},
        PropertiesToReplicate = properties or {},
    }, Replicator)

    GlobalReplicators[self] = true

    return self
end

-- Adds the key to the replication queue with an optional replacement value
function Replicator:Replicate(key, replacement)
    if table.find(self.PropertiesToReplicate, key) then
        self.ReplicatingQueue[key] = replacement or {Value = self.Holder[key]}
    end
end

function Replicator:Destroy()
    GlobalReplicators[self] = nil
end

RunService.PreAnimation:Connect(function()
    for replicator: Replicator in GlobalReplicators :: any do
        for property, data in replicator.ReplicatingQueue do
            for player in replicator.PlayersToReplicate do
                (replicator._ChangeRemote :: RemoteEvent):FireClient(player, property, data.Value)
            end
        end
    end
end)

return Replicator