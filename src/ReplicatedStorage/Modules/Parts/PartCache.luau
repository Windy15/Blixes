--!native

local CACHE_CFRAME = CFrame.new(1e6, 1e6, 1e6)
local CACHE_TAG = "CACHED_PARTCACHE"

export type PartCache = {
    CreatePool: (self: PartCache, poolKey: any, part: BasePart?) -> CachePool,
    GetPool: (self: PartCache, poolKey: any) -> CachePool?,
    IsCached: (self: PartCache, part: BasePart) -> boolean,
}

type CachePoolImpl = {
    StorePart: (self: CachePool, part: BasePart) -> (),
    GetPart: (self: CachePool) -> BasePart,
    ClearParts: (self: CachePool) -> (),
}

export type CachePool = typeof(setmetatable({} :: {
    Part: BasePart,
    [number]: BasePart,
}, {} :: CachePoolImpl))

local PartCache = {} :: PartCache
local Pools = {}
local CachePool = {} :: CachePoolImpl

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
        Part = part
    }, CachePool)
    Pools[poolKey] = pool :: CachePool

    return pool
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
    table.insert(self, part)
end

function CachePool:GetPart()
    local len = #self
    local part: BasePart = self[len]
    if part then
        part:RemoveTag(CACHE_TAG)
        self[len] = nil
    else
        return self.Part:Clone()
    end
    return part
end

function CachePool:ClearParts()
    for i, part in ipairs(self) do
        part:RemoveTag(CACHE_TAG)
        part:Destroy()
        self[i] = nil
    end
end

return PartCache