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

type OpenIndexNode = {
    _Next: OpenIndexNode?,
    Index: number,
}

export type GenerationId = typeof(setmetatable({} :: {
    _open_index_head: OpenIndexNode?,
    _objects: typeof(setmetatable(
        {} :: {[id]: object},
        {} :: {__mode: string}
    )),
    _ids: typeof(setmetatable(
        {} :: {[object]: id},
        {} :: {__mode: string}
    )),
}, {} :: GenerationIdImpl))

local ObjectsMeta = {__mode = "v"}
local IdsMeta = {__mode = "k"}

local GenerationId = {} :: GenerationIdImpl
GenerationId.__index = GenerationId

function GenerationId.new(initsize: number?)
    return setmetatable({
        _open_index_head = nil, -- Linked list containing indexes that are nil for O(1) id creation and prevent memory buildup
        _objects = setmetatable(initsize and table.create(initsize) or {}, ObjectsMeta),
        _ids = setmetatable({}, IdsMeta),
    }, GenerationId)
end

function GenerationId:GetTopId() -- Finds the index of the first nil value in _objects
    local id = 1
    for _ in ipairs(self._objects :: any) do
        id += 1
    end
    return id
end

function GenerationId:CreateId(object: object)
    local id
    local open_node = self._open_index_head
    while open_node and self._objects[open_node.Index] do -- If the index isn't actually open get rid of it
        local newhead = open_node._Next
        self._open_index_head = newhead
        open_node = newhead
    end

    if open_node then
        self._open_index_head = open_node._Next
        id = open_node.Index
    else
        id = #self._objects + 1
    end

    self._objects[id] = object
    self._ids[object] = id
    return id
end

function GenerationId:GetObject(id: id)
    return self._objects[id]
end

function GenerationId:GetId(object: object)
    return self._ids[object]
end

function GenerationId:RemoveId(object: object)
    local id = self._ids[object]
    if id then
        self._ids[object] = nil
        self._objects[id] = nil
        local newhead = { -- new open index for ids is available
            _Next = self._open_index_head,
            Index = id,
        }
        self._open_index_head = newhead
    end
end

return GenerationId