--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ReplicationRemote: UnreliableRemoteEvent = ReplicatedStorage.Remotes.ObjectReplication

type object = {[any]: any}
type propertyName = string

type Replicator = {
    Objects: typeof(setmetatable(
        {} :: {[object]: ReplicationData},
        {} :: {__mode: string}
    )),
    IdToObject: typeof(setmetatable(
        {} :: {[string]: object},
        {} :: {__mode: string}
    )),

    Replicate: (self: Replicator, object: object, property: string) -> (),
    AddObject: (self: Replicator, object: object, owner: Player, tracking: {[propertyName]: {[Player]: boolean}}?) -> (),
    GetObjectId: (self: Replicator, object: object) -> (),
    SetObjectTracking: (self: Replicator, object: object, tracking: boolean) -> (),
    RemoveObject: (self: Replicator, object: object) -> (),
}

type ReplicationData = {
    ObjectId: string, -- Unique identifier for object for server-client communication
    Owner: Player?, -- Owner of the object who will always get properties replicated to them

    LastValues: {[propertyName]: any}, -- Values of properties in the last frame; used by the tracker to check if they have changed
    TrackingProperties: {[propertyName]: {[Player]: boolean}}, -- Properties that will automatically track for changes and replicate

    ReplicateQueue: {[propertyName]: {[Player]: boolean}}, -- Currently replicating properties

    IsTracking: boolean, -- If the object is currently being tracked for changes
    IsReplicating: boolean, -- If the object is currently replicating properties
}

local Replicator = {
    -- If object gets gced so will it's replication and id data
    Objects = setmetatable({}, {__mode = "k"}),
    IdToObject = setmetatable({}, {__mode = "v"}),
} :: Replicator

local function getSpecialType(val: any)
    if type(val) == "table" and getmetatable(val) then -- For values that have metatables so they can be reconstructed on the client
        return val.__type
    end

    return nil
end

local ClassSerializers = {}

local function replicateData(player: Player, objId: string, property: propertyName, value: any)
    local typename = getSpecialType(value)
    if typename then
        local serializer = ClassSerializers[typename]
        if serializer then
            value = serializer(value)
        else
            error("No serializer found for "..typename)
        end
    end

    ReplicationRemote:FireClient(player, objId, property, value, typename)
end

local function getSerializedValue(object, property)
    local value = object[property]

    local typename = getSpecialType(value)
    if typename then
        local serializer = ClassSerializers[typename]
        if serializer then
            value = serializer(value)
        end
    end

    return value
end

RunService.PreAnimation:Connect(function()
    debug.profilebegin("Replicating Objects")
    for object, repData in Replicator.Objects do
        if repData.IsTracking then
            for property, playersToReplicate in repData.TrackingProperties do
                local value = getSerializedValue(object, property)
                local lastValue = repData.LastValues[property]

                if value ~= lastValue then -- If the property has changed
                    repData.ReplicateQueue[property] = playersToReplicate
                end

                repData.LastValues[property] = value
            end
        end

        if repData.IsReplicating then
            local objId = repData.ObjectId
            for property, playersToReplicate in repData.ReplicateQueue do
                local value = object[property]

                if repData.Owner then
                    replicateData(repData.Owner, objId, property, value)
                end
                for player in playersToReplicate do
                    replicateData(player, objId, property, value)
                end

                repData.ReplicateQueue[property] = nil
            end
        end
    end
    debug.profileend()
end)

function Replicator:Replicate(object: object, property: string, playersToReplicate: {Player}?)
    local repData = self.Objects[object]
    assert(repData, `Object {object} doesn't exist in replicator`)

    local replicatePlayersMap = repData.ReplicateQueue[property]
    if not replicatePlayersMap then
        replicatePlayersMap = {}
        repData.ReplicateQueue[property] = replicatePlayersMap
    end

    if playersToReplicate then
        for _, player in ipairs(playersToReplicate) do
            replicatePlayersMap[player] = true -- Only fire remote once for every recieving client
        end
    end
end

function Replicator:AddObject(object: object, owner: Player, trackingProperties: {[propertyName]: {[Player]: boolean}}?)
    assert(type(object) == "table", "Cannot add "..type(object).." to replicator")

    local LastValues = {}
    if trackingProperties then
        for property in trackingProperties do
            LastValues[property] = getSerializedValue(object, property)
        end
    end

    local objId = HttpService:GenerateGUID(false)
    self.IdToObject[objId] = object

    self.Objects[object] = {
        ObjectId = objId,
        Owner = owner,

        LastValues = LastValues,
        TrackingProperties = trackingProperties or {},

        ReplicateQueue = {},

        IsTracking = true,
        IsReplicating = true,
    }
end

function Replicator:GetObjectId(object: object)
    local repData = self.Objects[object]
    return repData and repData.ObjectId
end

function Replicator:SetObjectTracking(object: object, tracking: boolean)
    local repData = self.Objects[object]
    assert(repData, `Object {object} doesn't exist in replicator`)

    repData.IsTracking = tracking
end

function Replicator:RemoveObject(object: object)
    self.Objects[object] = nil
end

return Replicator