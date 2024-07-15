--!strict
--!native

export type Task = thread | RBXScriptConnection

type func = (...any) -> ...any

type UnifiedTaskImpl = {
    __index: UnifiedTaskImpl,

    new: (...Task) -> UnifiedTask,
    AddTask: (self: UnifiedTask, t: Task | func) -> (),
    RemoveTask: (self: UnifiedTask, t: Task) -> boolean,
    Run: (self: UnifiedTask, ...any?) -> (),
    Defer: (self: UnifiedTask) -> (),
    Finish: (self: UnifiedTask) -> (),
    CleanDeads: (self: UnifiedTask) -> (),
}

export type UnifiedTask = typeof(setmetatable({} :: {
    Tasks: {Task},
    Running: boolean,
    OnFinish: (taskThatFinished: Task?) -> ()?,
}, {} :: UnifiedTaskImpl))

local UnifiedTask = {} :: UnifiedTaskImpl
UnifiedTask.__index = UnifiedTask

function UnifiedTask.new(...: Task)
    local new = setmetatable({
        Tasks = {...},
        Running = false,
        OnFinish = nil,
    }, UnifiedTask)
    return new
end

function UnifiedTask:AddTask(t)
    if type(t) == "function" then
        local thread = coroutine.create(t)
        table.insert(self.Tasks, thread)
        if self.Running then
            coroutine.resume(thread)
        end
    elseif type(t) == "thread" then
        table.insert(self.Tasks, t)
        if self.Running then
            coroutine.resume(t)
        end
    else
        table.insert(self.Tasks, t)
    end
end

function UnifiedTask:RemoveTask(t: Task): boolean
    local index = table.find(self.Tasks, t)
    if index then
        table.remove(self.Tasks, index)
        return true
    end
    return false
end

function UnifiedTask:Run(...)
    self.Running = true
    for _, t in ipairs(self.Tasks) do
        if type(t) == "thread" then
            coroutine.resume(t, ...)
        end
    end
end

function UnifiedTask:Defer()
    self.Running = true
    for _, t in ipairs(self.Tasks) do
        if type(t) == "thread" then
            task.defer(t)
        end
    end
end

function UnifiedTask:Finish()
    self.Running = false
    local taskThatFinished = nil -- current thread could be inside an RBXScriptConnection
    local thisThread = coroutine.running()
    for i, t in ipairs(self.Tasks) do
        if t == thisThread then
            taskThatFinished = thisThread
        end
        self.Tasks[i] = nil
        if type(t) == "thread" and coroutine.status(t) ~= "running" then
            coroutine.close(t)
        elseif typeof(t) == "RBXScriptConnection" then
            t:Disconnect()
        end
    end
    if self.OnFinish then
        task.spawn(self.OnFinish, taskThatFinished)
    end
end

function UnifiedTask:CleanDeads()
    for i, t in ipairs(self.Tasks) do
        if type(t) == "thread" then
            if coroutine.status(t) == "dead" then
                table.remove(self.Tasks, i)
            end
        end
    end
    if #self.Tasks == 0 then
        self.Running = false
    end
end

return UnifiedTask