local StatModifier = {}
StatModifier.__index = StatModifier

function StatModifier.new(adder, multiplier, modifFunction)
    return setmetatable({
        Adder = adder,
        Multiplier = multiplier,
        ModifierFunction = modifFunction
    }, StatModifier)
end

return StatModifier