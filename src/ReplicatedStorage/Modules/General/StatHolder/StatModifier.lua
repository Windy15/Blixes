local StatModifier = {}
StatModifier.__index = StatModifier

function StatModifier.new(adder: number?, multiplier: number?, modifFunction: (self: {[any]: any}, val: number) -> number)
    return setmetatable({
        Adder = adder,
        Multiplier = multiplier,
        ModifierFunction = modifFunction
    }, StatModifier)
end

return StatModifier