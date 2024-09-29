--!native
--!strict

local CACHE_CFRAME = CFrame.new(1e6, 1e6, 1e6)
local CACHE_TAG = "CACHED_PARTCACHE"

export type PartCache = {
    CreatePool: (self: PartCache, poolKey: any, part: BasePart?) -> CachePool,
    GetPool: (self: PartCache, poolKey: any) -> CachePool?,
    IsCached: (self: PartCache, part: BasePart) -> boolean,
}

type CachePoolImpl = {
    __index: CachePoolImpl,

    StorePart: (self: CachePool, part: BasePart) -> (),
    GetPart: (self: CachePool) -> BasePart,
    ClearParts: (self: CachePool) -> (),
}

export type CachePool = typeof(setmetatable({} :: {
    Part: BasePart,
    Pool: {BasePart},
}, {} :: CachePoolImpl))

local PartCache = {} :: PartCache
local Pools = {}
local CachePool = {} :: CachePoolImpl
CachePool.__index = CachePool

function PartCache:CreatePool(poolKey: any, part: BasePart?)
    if Pools[poolKey] then
        error(`CachePool '{poolKey}' already exists`, 2)
    end

    if not part then
        if typeof(poolKey) == "Instance" then
            part = poolKey :: BasePart
        else
            error("poolKey or part arguement must be a BasePart", 2)
        end
    end

    local pool = setmetatable({
        Part = part,
        Pool = {},
    }, CachePool)
    Pools[poolKey] = pool :: CachePool

    return pool :: CachePool
end

function PartCache:GetPool(poolKey: any)
    return Pools[poolKey]
end

function PartCache:IsCached(part: BasePart)
    return part:HasTag(CACHE_TAG)
end

function CachePool:StorePart(part: BasePart)
    part.CFrame = CACHE_CFRAME
    part:AddTag(CACHE_TAG)
    table.insert(self.Pool, part)
end

function CachePool:GetPart()
    local len = #self
    local part = self.Pool[len]
    if part then
        part:RemoveTag(CACHE_TAG)
        self.Pool[len] = nil
    else
        return self.Part:Clone()
    end
    return part
end

function CachePool:ClearParts()
    for i, part in self.Pool do
        part:RemoveTag(CACHE_TAG)
        part:Destroy()
        self.Pool[i] = nil
    end
end

return PartCache