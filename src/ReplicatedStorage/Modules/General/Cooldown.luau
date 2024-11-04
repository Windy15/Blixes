type CooldownImpl = {
    __index: CooldownImpl,

    new: (duration: number) -> Cooldown,
    Reset: (self: Cooldown, timeOffset: number?) -> (),
    IsActive: (self: Cooldown) -> (),
    GetTimeLeft: (self: Cooldown) -> (),
}

export type Cooldown = typeof(setmetatable({} :: {
    Duration: number,
    ResetTime: number,
}, {} :: CooldownImpl))

local Cooldown = {} :: CooldownImpl
Cooldown.__index = Cooldown

function Cooldown.new(duration)
    return setmetatable({
        Duration = duration,
        ResetTime = 0,
    }, Cooldown)
end

function Cooldown:Reset(timeOffset)
    local resetTime = os.clock()
    self.ResetTime = if timeOffset then resetTime - timeOffset else resetTime
end

function Cooldown:IsActive()
    return os.clock() - self.ResetTime < self.Duration
end

function Cooldown:GetTimeLeft()
    return os.clock() - self.ResetTime
end

return Cooldown