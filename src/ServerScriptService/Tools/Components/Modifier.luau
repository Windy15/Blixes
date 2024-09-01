--!strict

local Types = require(script.Parent.Types)

type modfunc = (input: number) -> number

type ModifierImpl = {
    __index: ModifierImpl,

    new: (holder: Types.Holder, ...string) -> (),
    RegisterProperty: (self: Modifier, property: string) -> (),
    GetModified: (self: Modifier, property: string) -> number,
    AddModifyFunc: (self: Modifier, property: string, func: modfunc) -> (),
    RemoveModifyFunc: (self: Modifier, property: string, func: modfunc) -> boolean,
}

export type Modifier = typeof(setmetatable({} :: {
    Holder: Types.Holder,
    Properties: {
        [string]: ModifyTable
    }
}, {} :: ModifierImpl))

type ModifyTable = {
    Adder: number,
    Multiplier: number,
    ModifyFunctions: {modfunc}
}

local ModifyTable = {}

function ModifyTable.new()
    return {
        Adder = 0,
        Multiplier = 1,
        ModifyFunctions = {},
    }
end

local Modifier = {} :: ModifierImpl
Modifier.__index = Modifier

function Modifier.new(holder, ...)
    local self = setmetatable({
        Holder = holder,
        Properties = {}
    }, Modifier) :: Modifier

    for i = 1, select("#", ...) do
        self.Properties[select(i, ...)] = ModifyTable.new()
    end

    return self
end

function Modifier:RegisterProperty(property)
    if not self.Properties[property] then
        self.Properties[property] = ModifyTable.new()
    end
end

function Modifier:GetModified(property)
    local value = self.Holder[property]
    local modify = self.Properties[property]
    if not modify then return value end

    value = value * modify.Multiplier + modify.Adder
    for _, func in modify.ModifyFunctions do
        value = func(value)
    end

    return value
end

local function checkProperty(self: Modifier, property: string)
    local modify = self.Properties[property]
    if not modify then
        error(`Could not find property {property} in Modifier`, 2)
    end
    return modify
end

function Modifier:AddModifyFunc(property, func)
    local modify = checkProperty(self, property)
    table.insert(modify.ModifyFunctions, func)
end

function Modifier:RemoveModifyFunc(property, func)
    local modify = checkProperty(self, property)
    local index = table.find(modify.ModifyFunctions, func)
    if index then
        table.remove(modify.ModifyFunctions, index)
        return true
    end
    return false
end

return Modifier