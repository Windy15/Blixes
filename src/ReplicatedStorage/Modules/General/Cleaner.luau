--!native
--!strict

type DestroyableMeta = {
    __index: DestroyableMeta,
    Destroy: (self: Destroyable) -> (),
}

export type Destroyable = typeof(setmetatable({}, {} :: DestroyableMeta))

export type Cleanable = thread | RBXScriptConnection | Instance | Destroyable

type func = (...any) -> ...any

type CleanerImpl = {
    __index: CleanerImpl,
    __type: string,

    new: (...Cleanable) -> Cleaner,
    AddObject: (self: Cleaner, t: Cleanable | func) -> (),
    RemoveObject: (self: Cleaner, t: Cleanable) -> boolean,
    RunThreads: (self: Cleaner, ...any?) -> (),
    DeferThreads: (self: Cleaner, ...any?) -> (),
    Finish: (self: Cleaner) -> (),
    CleanDeadThreads: (self: Cleaner) -> (),
}

export type Cleaner = typeof(setmetatable({} :: {
    Objects: {Cleanable},
    OnFinish: (taskThatFinished: Cleanable?) -> ()?,
}, {} :: CleanerImpl))

local Cleaner = {} :: CleanerImpl
Cleaner.__index = Cleaner
Cleaner.__type = "Cleaner"

function Cleaner.new(...)
    local self = setmetatable({
        Objects = {...},
        OnFinish = nil,
    }, Cleaner)

    return self
end

function Cleaner:AddObject(t)
    if type(t) == "function" then
        local thread = coroutine.create(t)
        table.insert(self.Objects, thread)
    else
        table.insert(self.Objects, t)
    end
end

function Cleaner:RemoveObject(t)
    local index = table.find(self.Objects, t)
    if index then
        table.remove(self.Objects, index)
        return true
    end
    return false
end

function Cleaner:RunThreads(...)
    for _, t in ipairs(self.Objects) do
        if type(t) == "thread" then
            coroutine.resume(t, ...)
        end
    end
end

function Cleaner:DeferThreads(...)
    for _, t in ipairs(self.Objects) do
        if type(t) == "thread" then
            task.defer(t, ...)
        end
    end
end

function Cleaner:Finish(...) -- Cleans all objects
    for i, t in ipairs(self.Objects) do
        self.Objects[i] = nil
        if type(t) == "thread" and coroutine.status(t) ~= "running" then
            coroutine.close(t)
        elseif typeof(t) == "RBXScriptConnection" then
            t:Disconnect()
        elseif typeof(t) == "table" then
            t:Destroy()
        elseif typeof(t) == "Instance" then
            if t:IsA("AnimationTrack") then
                t:Stop()
            end
            t:Destroy()
        end
    end
    if self.OnFinish then
        task.spawn(self.OnFinish, ...)
    end
end

function Cleaner:CleanDeadThreads()
    for i, t in ipairs(self.Objects) do
        if type(t) == "thread" then
            if coroutine.status(t) == "dead" then
                table.remove(self.Objects, i)
            end
        end
    end
end

return Cleaner