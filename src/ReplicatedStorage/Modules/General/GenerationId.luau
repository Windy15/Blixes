--!native
--!strict

type object = any
type id = number

type GenerationIdImpl = {
    __index: GenerationIdImpl,

    new: (initsize: number?) -> GenerationId,
    CreateId: (self: GenerationId, object: object) -> id,
    GetTopId: (self: GenerationId) -> id,
    GetObject: (self: GenerationId, id: id) -> object?,
    GetId: (self: GenerationId, object: object) -> id?,
    RemoveId: (self: GenerationId, object: object) -> (),
}

export type GenerationId = typeof(setmetatable({} :: {
    _opensize: number,
    _openindexes: {number},
    _objects: {[id]: object},
    _ids: {[object]: id},
}, {} :: GenerationIdImpl))

local GenerationId = {} :: GenerationIdImpl
GenerationId.__index = GenerationId

function GenerationId.new(initsize)
    local self = setmetatable({
        _opensize = 0,
        _openindexes = table.create(initsize or 0),
        _objects = table.create(initsize or 0),
        _ids = {},
    }, GenerationId)
    return self
end

function GenerationId:CreateId(object)
    local openId = self._opensize
    local id
    if openId ~= 0 then
        id = self._openindexes[openId]
        self._openindexes[openId] = nil
        self._opensize = openId - 1
    end
    while id and self._objects[id] do
        openId = self._opensize
        id = self._openindexes[openId]
        self._openindexes[openId] = nil
        self._opensize = openId - 1
    end
    if not id then
        id = #self._objects + 1
    end
    self._objects[id] = object
    self._ids[object] = id
    return id
end

function GenerationId:GetTopId() -- Finds the index of the first nil value in _objects
    local id = 1
    for _ in ipairs(self._objects :: any) do
        id += 1
    end
    return id
end

function GenerationId:GetObject(id: id)
    return self._objects[id]
end

function GenerationId:GetId(object: object)
    return self._ids[object]
end

function GenerationId:RemoveId(object)
    local id = self._ids[object]
    if id then
        self._ids[object] = nil
        self._objects[id] = nil
        local openId = self._opensize + 1
        self._openindexes[openId] = id
        self._opensize = openId
    end
end

return GenerationId