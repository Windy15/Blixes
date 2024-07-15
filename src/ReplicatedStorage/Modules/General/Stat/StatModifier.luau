local StatModifier = {}
StatModifier.__index = StatModifier

export type StatModifier = typeof(setmetatable({} :: {
    Adder: number?,
    Multiplier: number?,
    ModifierFunction: (self: {[any]: any}, val: number) -> number,
}, {} :: typeof(StatModifier)))

function StatModifier.new(adder: number?, multiplier: number?, modifFunction: (self: {[any]: any}, val: number) -> number)
    return setmetatable({
        Adder = adder,
        Multiplier = multiplier,
        ModifierFunction = modifFunction,
    }, StatModifier)
end

return StatModifier