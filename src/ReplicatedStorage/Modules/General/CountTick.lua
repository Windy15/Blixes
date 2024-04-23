local RunService = game:GetService("RunService")

local CountTick = {}
CountTick.__index = CountTick

function CountTick.new(start, finish, roundTo, onTick)
    local new = setmetatable({
        StartTime = start,
        FinishTime = finish,
        RoundTo = 1 / roundTo,

        OnTick = onTick,
        OnTickEvent = nil,

        TimeRan = 0,

        _SimulationEvent = RunService.PostSimulation
    }, CountTick)

    return new
end

local function getTime(start, finish, timeRan)
    return start < finish and start + timeRan or start - timeRan
end

function CountTick:Start()
    assert(not self.CountConnection, "Count object has already been started")

    local totalTime = math.abs(self.StartTime - self.FinishTime)

    local startTime = os.clock()
    local lastTime = nil

    self.CountConnection = self._SimulationEvent:Connect(function(deltaTime)
        local runTime = os.clock() - startTime
        self.TimeRan = runTime
        local roundedTime = math.floor(runTime * self.RoundTo + deltaTime) / self.RoundTo
        if runTime >= totalTime then
            self:Stop()
        elseif roundedTime ~= lastTime then
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

function CountTick:Stop()
    if self.CountConnection then
        self.CountConnection:Disconnect()
    end
end

return CountTick