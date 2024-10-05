--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicationRemote: UnreliableRemoteEvent = ReplicatedStorage.Remotes.ObjectReplication

type object = {[any]: any}

type Replicator = {
    IdToObject: typeof(setmetatable(
        {} :: {[string]: object},
        {} :: {__mode: string}
    )),

    RegisterObject: (self: Replicator, objId: string, object: object) -> (),
}

local Replicator = {
    IdToObject = setmetatable({}, {__mode = "v"}),
} :: Replicator

local ClassDeserializers = {}

ReplicationRemote.OnClientEvent:Connect(function(objId: string, property: string, value: any, typename: string?)
    local object = Replicator.IdToObject[objId]
    if not object then
        error("Object: "..objId..(typename and " of type "..typename or "").." does not or no longer exists in replicator")
    end

    if typename then
        local deserializer = ClassDeserializers[typename]
        if deserializer then
            rawset(object, property, deserializer(value))
        else
            error("No deserialzier found for "..typename)
        end
    else
        object[property] = value
    end
end)

function Replicator:RegisterObject(objId: string, object: object)
    Replicator.IdToObject[objId] = object
end

return Replicator