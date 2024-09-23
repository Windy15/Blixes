--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local ObjectStorage = {} :: ObjectStorageImpl<any>
ObjectStorage.__index = ObjectStorage

local InstToObjMeta = {__mode = "k"}
local ObjToInstMeta = {__mode = "kv"}

function ObjectStorage.new()
    return setmetatable({
        InstToObj = setmetatable({}, InstToObjMeta),
        ObjToInst = setmetatable({}, ObjToInstMeta),

        OnObjectAdded = Signal.new(),
        OnObjectRemoved = Signal.new(),
    }, ObjectStorage)
end

function ObjectStorage:GetObject(inst)
    return self.InstToObj[inst]
end

function ObjectStorage:GetInstance(obj)
    return self.ObjToInst[obj]
end

function ObjectStorage:AddObject(inst, obj)
    self.InstToObj[inst] = obj
    self.ObjToInst[obj] = inst
    self.OnObjectAdded:Fire(obj, inst)
end

function ObjectStorage:RemoveObject(inst)
    local obj = self.InstToObj[inst]
    self.InstToObj[inst] = nil
    if obj then
        self.ObjToInst[obj] = nil
        self.OnObjectRemoved:Fire(obj, inst)
    end
end

type ObjectStorageImpl<T> = {
    __index: ObjectStorageImpl<T>,

    new: () -> ObjectStorage<T>,
    GetObject: (self: ObjectStorage<T>, inst: Instance) -> T,
    GetInstance: (self: ObjectStorage<T>, obj: T) -> Instance,

    AddObject: (self: ObjectStorage<T>, inst: Instance, obj: T) -> (),
    RemoveObject: (self: ObjectStorage<T>, inst: Instance) -> (),
}

export type ObjectStorage<T> = typeof(setmetatable({} :: {
    InstToObj: typeof(setmetatable({} :: {[Instance]: T}, {} :: {__mode: string})),
    ObjToInst: typeof(setmetatable({} :: {[T]: Instance}, {} :: {__mode: string})),

    OnObjectAdded: Signal.Signal<T, Instance>,
    OnObjectRemoved: Signal.Signal<T, Instance>,
}, {} :: ObjectStorageImpl<T>))

local GlobalObjects = {
    Storages = {
        Tools = ObjectStorage.new(),
---@diagnostic disable-next-line: undefined-type
    } :: {[string]: ObjectStorage<unknown>}
}

function GlobalObjects:FindObject(inst: Instance)
    for category, storage in GlobalObjects.Storages do
        for keyinst, obj in storage.InstToObj :: any do
            if keyinst == inst then
                return obj, category
            end
        end
    end
    return nil, "None"
end

return GlobalObjects