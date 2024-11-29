local Types = {}

export type RegionImpl = {
    __index: RegionImpl,

    IsPointInRegion: (self: Region, point: Vector3) -> boolean,
    GetPlayersInRegion: (self: Region) -> {Player},
}

export type Region = typeof(setmetatable({} :: {}, {} :: RegionImpl))

return Types