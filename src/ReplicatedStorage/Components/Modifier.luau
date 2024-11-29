--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

type modfunc = (input: number) -> number

type ModifierImpl = {
    __index: ModifierImpl,

    new: (holder: any, ...string) -> Modifier,
    RegisterProperty: (self: Modifier, stat: string) -> (),
    GetModified: (self: Modifier, stat: string, customValue: number?) -> number,
    IncAdder: (self: Modifier, stat: string, value: number, prevValue: number?) -> (),
    IncMultiplier: (self: Modifier, stat: string, value: number, prevValue: number?) -> (),
    AddModifyFunc: (self: Modifier, stat: string, func: modfunc) -> (),
    RemoveModifyFunc: (self: Modifier, stat: string, func: modfunc) -> boolean,
    GetModifyTable: (self: Modifier, stat: string) -> ModifyTable,

    Destroy: (self: Modifier) -> (),
}

export type Modifier = typeof(setmetatable({} :: {
    Holder: any,
    Stats: {
        [string]: ModifyTable
    }
}, {} :: ModifierImpl))

type ModifyTable = {
    Adder: number,
    Multiplier: number,
    ModifyFunctions: {modfunc},
    OnChanged: Signal.Signal<>,
}

local ModifyTable = {}

function ModifyTable.new()
    return {
        Adder = 0,
        Multiplier = 1,
        ModifyFunctions = {},
        OnChanged = Signal.new(),
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

    local base = value
    value = value * modify.Multiplier + modify.Adder

    local total = 0
    for _, func in modify.ModifyFunctions do
        total += func(base) - base
    end
    value += total

    return value
end

local function checkProperty(self: Modifier, stat: string)
    local modify = self.Stats[stat]
    if not modify then
        if type(stat) ~= "string" then
            error(`Expected string for stat name got {type(stat)}`, 3)
        else
            error(`Could not find stat {stat} in Modifier`, 3)
        end
    end
    return modify
end

function Modifier:IncAdder(stat, value, prev)
    local modify = checkProperty(self, stat)

    modify.Adder += value
    if prev then
        modify.Adder -= prev
    end

    modify.OnChanged:Fire()
end

function Modifier:IncMultiplier(stat, value, prev)
    local modify = checkProperty(self, stat)

    modify.Multiplier += value
    if prev then
        modify.Multiplier -= prev
    end

    modify.OnChanged:Fire()
end

function Modifier:AddModifyFunc(stat, func)
    local modify = checkProperty(self, stat)
    table.insert(modify.ModifyFunctions, func)

    modify.OnChanged:Fire()
end

function Modifier:RemoveModifyFunc(stat, func)
    local modify = checkProperty(self, stat)
    local index = table.find(modify.ModifyFunctions, func)
    if index then
        table.remove(modify.ModifyFunctions, index)
    end
    modify.OnChanged:Fire()
    return index ~= nil
end

function Modifier:GetModifyTable(stat)
    return self.Stats[stat]
end

function Modifier:Destroy()
    table.clear(self.Stats)
end

return Modifier