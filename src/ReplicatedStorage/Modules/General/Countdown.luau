--!native
--!strict

local RunService = game:GetService("RunService")

export type CountdownImpl = {
    __index: CountdownImpl,
    __type: "Countdown",

    new: (start: number, finish: number, roundTo: number?, onTick: (currentTime: number) -> ()?) -> (),
    Start: (self: Countdown) -> (),
    Stop: (self: Countdown) -> ()
}

export type Countdown = typeof(setmetatable({} :: {
    StartTime: number,
    FinishTime: number,
    RoundTo: number,

    OnTick: (currentTime: number) -> ()?,
    OnTickEvent: any,

    TimeRan: number,

    _CountConnection: RBXScriptConnection?,
    _SimulationEvent: RBXScriptSignal,
}, {} :: CountdownImpl))

local Countdown = {} :: CountdownImpl
Countdown.__index = Countdown
Countdown.__type = "Countdown"

function Countdown.new(start: number, finish: number, roundTo: number?, onTick: (currentTime: number) -> ()?): Countdown
    local self = setmetatable({
        StartTime = start,
        FinishTime = finish,
        RoundTo = roundTo or 1,

        OnTick = onTick,
        OnTickEvent = nil,

        TimeRan = 0,

        _SimulationEvent = RunService.PostSimulation
    }, Countdown)

    return self
end

local function getTime(start: number, finish: number, timeRan: number)
    return if start < finish then start + timeRan else start - timeRan
end

function Countdown:Start()
    if self._CountConnection then
        error("Countdown has already been started", 2)
    end

    local totalTime = math.abs(self.StartTime - self.FinishTime)

    local startTime = os.clock()
    local lastTime = nil

    self._CountConnection = self._SimulationEvent:Connect(function(deltaTime)
        local runTime = os.clock() - startTime
        self.TimeRan = runTime
        local roundedTime = math.round(runTime / self.RoundTo) * self.RoundTo

        if runTime - deltaTime >= totalTime then
            self:Stop()
        elseif roundedTime ~= lastTime then
            lastTime = roundedTime
            local currentTIme = getTime(self.StartTime, self.FinishTime, roundedTime)
            if self.OnTick then
                self.OnTick(currentTIme)
            end
            if self.OnTickEvent then
                self.OnTickEvent:Fire(currentTIme)
            end
        end
    end)
end

function Countdown:Stop()
    if self._CountConnection then
        self._CountConnection:Disconnect()
    end
end

return Countdown