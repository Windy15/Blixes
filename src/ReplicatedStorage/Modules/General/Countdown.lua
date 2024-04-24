local RunService = game:GetService("RunService")

local Countdown = {}
Countdown.__index = Countdown

function Countdown.new(start, finish, roundTo, onTick)
    local new = setmetatable({
        StartTime = start,
        FinishTime = finish,
        RoundTo = roundTo or 1,

        OnTick = onTick,
        OnTickEvent = nil,

        TimeRan = 0,

        _SimulationEvent = RunService.PostSimulation
    }, Countdown)

    return new
end

local function getTime(start, finish, timeRan)
    return start < finish and start + timeRan or start - timeRan
end

function Countdown:Start()
    assert(not self.CountConnection, "Count object has already been started")

    local totalTime = math.abs(self.StartTime - self.FinishTime)

    local startTime = os.clock()
    local lastTime = nil

    self.CountConnection = self._SimulationEvent:Connect(function(deltaTime)
        local runTime = os.clock() - startTime
        self.TimeRan = runTime
        if runTime >= totalTime then
            self:Stop()
        elseif not lastTime or runTime - lastTime >= self.RoundTo then
            lastTime = runTime - deltaTime
            if self.OnTick then
                self.OnTick(getTime(self.StartTime, self.FinishTime, math.round(runTime / self.RoundTo) * self.RoundTo), self)
            end
            if self.OnTickEvent then
                self.OnTickEvent:Fire(getTime(self.StartTime, self.FinishTime, math.round(runTime / self.RoundTo) * self.RoundTo), self)
            end
        end
    end)
end

function Countdown:Stop()
    if self.CountConnection then
        self.CountConnection:Disconnect()
    end
end

return Countdown