--!nonstrict

local CACHE_CFRAME = CFrame.new(1e6, 1e6, 1e6)

export type PartCache = {
    CreatePool: (self: PartCache, poolKey: any, instance: Instance) -> (),
    [any]: CachePool
}

type CachePoolImpl = {
    StorePart: (self: CachePool, part: Instance) -> (),
    GetPart: (self: CachePool) -> (),
}

export type CachePool = typeof(setmetatable({} :: {
    Part: Instance,
    [number]: Instance
}, {} :: CachePoolImpl))

local PartCache= {} :: PartCache
local CachePool = {} :: CachePoolImpl

function PartCache:CreatePool(poolKey, instance)
    assert(not PartCache[poolKey], `CachePool '{poolKey}' already exists`)
    PartCache[poolKey] = setmetatable({
        Part = typeof(poolKey) == "Instance" and poolKey or instance
    }, CachePool)
end

function CachePool:StorePart(part)
    part.CFrame = CACHE_CFRAME
    table.insert(self, part)
end

function CachePool:GetPart()
    local part = self[#self]
    if part then
        part = part:Clone()
        self[#self] = nil
    else
        return self.Part:Clone()
    end
    return part
end

return PartCache