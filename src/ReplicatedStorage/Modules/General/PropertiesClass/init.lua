local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local Properties = {}
Properties.__index = Properties

function Properties.new(new)
	new = setmetatable(new or {}, Properties)

	new.PropertyChanged = Signal.new()
	new.StatModifiers = {}

	return new
end

function Properties:GetModified(index)
	local value = self[index]

	if not value then return nil end

	assert(self.StatModifiers[index], "Index '"..index.."' is not a stat for this table")

    local muls = {}
    local funcs = {}

	for _, modifier in ipairs(self.StatModifiers[index]) do
		if modifier.Adder then
			value += modifier.Adder
		end

        if modifier.Multiplier then table.insert(muls, modifier.Multiplier) end
        if modifier.ModifierFunction then table.insert(funcs, modifier.ModifierFunction) end
	end

	for _, mul in ipairs(muls) do
		value *= mul
	end

    for _, func in ipairs(funcs) do
        value = func(value)
    end

	return value
end

function Properties:SetStat(index)
	self.StatModifiers[index] = {
        -- StatModifier.new()
    }
end

function Properties:SetValue(index, value)
	local oldValue = self[index]
	self[index] = value
	self.PropertyChanged:Fire(index, value, oldValue)
end

return Properties