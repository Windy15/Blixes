local List = {}
List.__index = List

function List.new(list, meta)
    meta.__index = meta
    return setmetatable(setmetatable(list, List), meta)
end

List.__len = function(self)
    local len = 0

    for _ in pairs(self) do
        len += 1
    end

    return len
end

return List