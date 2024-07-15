--!native
--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StatModifier = require(script.StatModifier)

type StatImpl = {
    __index: StatImpl,
    __tostring: <T>(self: Stat<T>) -> string,
    __eq: <T1, T2>(self: Stat<T1>, other: Stat<T2>) -> boolean,
    __lt: <T1, T2>(self: Stat<T1>, other: Stat<T2>) -> boolean,
    __le: <T1, T2>(self: Stat<T1>, other: Stat<T2>) -> boolean,

    new: <T>(value: T) -> Stat<T>,
    GetModified: <T>(self: Stat<T>) -> T,
}

export type Stat<T> = {
    Value: T,
    StatModifiers: {StatModifier.StatModifier},
    Changed: Signal.Signal,
}

local Stat = {}
Stat.__index = Stat

function Stat.new(value)
    return setmetatable({
        Value = value,
        StatModifiers = {},
        Changed = Signal.new()
    }, Stat)
end

function Stat:GetModified()
    local value = self.Value

    local adders = table.create(#self.StatModifiers)
    local funcs = table.create(#self.StatModifiers)

	for _, modifier in ipairs(self.StatModifiers) do
		if modifier.Multiplier then -- Multipliers first
			value *= modifier.Multiplier
		end
        if modifier.Adder then
			table.insert(adders, modifier.Adder) -- Then adders
		end
        if modifier.ModifierFunction then
			table.insert(funcs, modifier.ModifierFunction)-- Then functions
		end
	end

	for _, add in ipairs(adders) do
		value += add
	end

    for _, func in ipairs(funcs) do
        value = func(self, value)
    end

	return value
end

Stat.__tostring = function(self)
    return tostring(self.Value)
end

Stat.__eq = function(self, other)
    return self.Value == other.Value
end

Stat.__lt = function(self, other)
    return self.Value < other.Value
end

Stat.__le = function(self, other)
    return self.Value <= other.Value
end

return Stat