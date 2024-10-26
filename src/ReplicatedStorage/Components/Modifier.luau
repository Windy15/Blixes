--!strict

local Types = require(script.Parent.Types)

type modfunc = (input: number) -> number

type ModifierImpl = {
    __index: ModifierImpl,

    new: (holder: Types.Holder, ...string) -> Modifier,
    RegisterProperty: (self: Modifier, stat: string) -> (),
    GetModified: (self: Modifier, stat: string, customValue: number?) -> number,
    AddModifyFunc: (self: Modifier, stat: string, func: modfunc) -> (),
    RemoveModifyFunc: (self: Modifier, stat: string, func: modfunc) -> boolean,
    GetModifyTable: (self: Modifier, stat: string) -> ModifyTable,

    Destroy: (self: Modifier) -> (),
}

export type Modifier = typeof(setmetatable({} :: {
    Holder: Types.Holder,
    Stats: {
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
        Stats = {}
    }, Modifier) :: Modifier

    for i = 1, select("#", ...) do
        self.Stats[select(i, ...)] = ModifyTable.new()
    end

    return self
end

function Modifier:RegisterProperty(stat)
    if not self.Stats[stat] then
        self.Stats[stat] = ModifyTable.new()
    end
end

function Modifier:GetModified(stat, customValue)
    local value = customValue or self.Holder[stat]
    local modify = self.Stats[stat]
    if not modify then return value end

    value = value * modify.Multiplier + modify.Adder
    for _, func in modify.ModifyFunctions do
        value = func(value)
    end

    return value
end

local function checkProperty(self: Modifier, stat: string)
    local modify = self.Stats[stat]
    if not modify then
        error(`Could not find stat {stat} in Modifier`, 2)
    end
    return modify
end

function Modifier:AddModifyFunc(stat, func)
    local modify = checkProperty(self, stat)
    table.insert(modify.ModifyFunctions, func)
end

function Modifier:RemoveModifyFunc(stat, func)
    local modify = checkProperty(self, stat)
    local index = table.find(modify.ModifyFunctions, func)
    if index then
        table.remove(modify.ModifyFunctions, index)
        return true
    end
    return false
end

function Modifier:GetModifyTable(stat)
    return self.Stats[stat]
end

function Modifier:Destroy()
    table.clear(self.Stats)
end

return Modifier