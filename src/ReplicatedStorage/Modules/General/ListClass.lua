--!strict

export type ListImpl = {
    __index: ListImpl,
    __len: (self: any) -> number,
    new: <T, META>(list: T, meta: META) -> List<T, META>
}

type ListMeta = {
    __index: ListMeta
}

type ListSelfMeta<T> = typeof(setmetatable({}, {} :: any)) & T

export type List<T, META> = typeof(setmetatable(
    {},
    {} :: META & ListMeta
)) & ListSelfMeta<T>

local List = {} :: ListImpl
List.__index = List

function List.new<T, META>(list: T, meta: META): List<T, META>
    (meta :: META & ListMeta).__index = meta :: META & ListMeta
    return setmetatable(setmetatable(list :: any, List), meta)
end

List.__len = function(self: any): number
    local len = 0

    for _ in pairs(self) do
        len += 1
    end

    return len
end

return List