--!native
--!strict

local RunService = game:GetService("RunService")

export type Worker = typeof(setmetatable({} :: {
    ResumedTime: number,
    MaxTime: number,
    SimulationEvent: RBXScriptSignal,
    Thread: thread,
}, {} :: WorkerImpl))

type WorkerImpl = {
    __index: WorkerImpl,

    new: (maxTime: number, simulationEvent: RBXScriptSignal) -> Worker,
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

function Worker.new(maxTime, simulationEvent)
    assert(YieldingWorkers[simulationEvent], "Invalid simulation event")
    return setmetatable({
        ResumedTime = os.clock(),
        MaxTime = maxTime,
        SimulationEvent = simulationEvent,
        Thread = coroutine.running(),
    }, Worker)
end

function Worker:Start()
    self.ResumedTime = os.clock()
end

function Worker:Step()
    if os.clock() - self.ResumedTime > self.MaxTime then
        self.Thread = coroutine.running()
        table.insert(YieldingWorkers[self.SimulationEvent], self)
        coroutine.yield()
    end
end

for event, yields in YieldingWorkers do
    event:Connect(function()
        local copy: typeof(yields) = table.create(#yields)
        for i, worker in copy do
            yields[i] = nil
            copy[i] = worker
        end
        for _, worker in copy do
            worker:Start()
            coroutine.resume(worker.Thread)
        end
    end)
end

return Worker