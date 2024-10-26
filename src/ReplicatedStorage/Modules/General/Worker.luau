--!strict

local RunService = game:GetService("RunService")

export type Worker = typeof(setmetatable({} :: {
    ResumedTime: number,
    TimeLimit: number,
    SimulationEvent: RBXScriptSignal,
    Thread: thread,
}, {} :: WorkerImpl))

type WorkerImpl = {
    __index: WorkerImpl,

    new: (timeLimit: number, simulationEvent: RBXScriptSignal) -> Worker,
    Start: (self: Worker) -> (),
    Step: (self: Worker) -> (),
}

local Worker = {} :: WorkerImpl
Worker.__index = Worker

local YieldingWorkers = {
    [RunService.PreRender] = {},
    [RunService.PreAnimation] = {},
    [RunService.PreSimulation] = {},
    [RunService.PostSimulation] = {},
} :: {[RBXScriptSignal]: {Worker}}

function Worker.new(timeLimit, simulationEvent)
    assert(YieldingWorkers[simulationEvent], "Invalid simulation event")
    return setmetatable({
        ResumedTime = os.clock(),
        TimeLimit = timeLimit,
        SimulationEvent = simulationEvent,
        Thread = coroutine.running(),
    }, Worker)
end

function Worker:Start()
    self.ResumedTime = os.clock()
end

function Worker:Step()
    if os.clock() - self.ResumedTime > self.TimeLimit then
        self.Thread = coroutine.running()
        table.insert(YieldingWorkers[self.SimulationEvent], self)
        coroutine.yield()
    end
end

for simulationEvent, yields in YieldingWorkers do
    simulationEvent:Connect(function()
        local copy: typeof(yields) = table.clone(yields)
        table.clear(yields)
        -- clone and clear yields table to deal with race conditions
        for _, worker in copy do
            worker:Start()
            coroutine.resume(worker.Thread)
        end
    end)
end

return Worker