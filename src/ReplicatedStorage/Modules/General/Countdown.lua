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
    if self.CountConnection then
        error("Countdown has already been started", 2)
    end

    local totalTime = math.abs(self.StartTime - self.FinishTime)

    local startTime = os.clock()
    local lastTime = nil

    self.CountConnection = self._SimulationEvent:Connect(function(deltaTime)
        local runTime = os.clock() - startTime
        self.TimeRan = runTime
        local roundedTime = math.round(runTime / self.RoundTo) * self.RoundTo

        if runTime - deltaTime >= totalTime then
            self:Stop()
        elseif roundedTime ~= lastTime and (runTime - deltaTime <= roundedTime and runTime + deltaTime >= roundedTime)  then
            lastTime = roundedTime
            if self.OnTick then
                self.OnTick(getTime(self.StartTime, self.FinishTime, roundedTime), self)
            end
            if self.OnTickEvent then
                self.OnTickEvent:Fire(getTime(self.StartTime, self.FinishTime, roundedTime), self)
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