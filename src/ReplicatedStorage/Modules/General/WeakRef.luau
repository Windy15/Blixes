--strict

type WeakRefImpl<T> = {
    __mode: "v",

    new: (value: T) -> WeakRef<T>
}

export type WeakRef<T> = typeof(setmetatable({} :: {
    Value: T
}, {} :: WeakRefImpl<T>))

local WeakRef = {} :: WeakRefImpl<any>
WeakRef.__mode = "v"

function WeakRef.new(value)
    return setmetatable({
        Value = value,
    }, WeakRef)
end

return WeakRef