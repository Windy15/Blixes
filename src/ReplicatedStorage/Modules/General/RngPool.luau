--!native
--!strict

type RngPoolImpl = {
    __index: RngPoolImpl,
    __type: string,

    new: (pool: Pool, rngState: Random?) -> RngPool,
    PickRandom: (self: RngPool) -> (any, number),
    GetPercentages: (self: RngPool) -> {[any]: number}
}

export type RngPool = typeof(setmetatable({} :: {
    RngState: Random,
    Pool: Pool,
}, {} :: RngPoolImpl))

export type Pool = {
    [any]: number
}

local RngPool = {}
RngPool.__index = RngPool
RngPool.__type = "RngPool"

function RngPool.new(pool: Pool, rngState: Random?): RngPool
    return setmetatable({
        RngState = rngState or Random.new(),
        Pool = pool
    }, RngPool)
end

function RngPool:PickRandom(): (any, number)
    local weightCounter = 0
    for _, weight in self.Pool do
        weightCounter += weight
    end
    local chosen = self.RngState:NextNumber(0, weightCounter)
    for item, weight in self.Pool do
        weightCounter -= weight
        if chosen > weightCounter then
            return item, weight
        end
    end
    error("Rng selection failed: no item picked", 2)
end

function RngPool:GetPercentages(): {[any]: number}
    local percentages = {}
    local sum = 0
    for _, weight in self.Pool do
        sum += weight
    end
    for item, weight in self.Pool do
        percentages[item] = weight / sum * 100
    end
    return percentages
end

return RngPool