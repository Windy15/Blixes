local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
require(script.StatModifierClass)

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

    local adders = table.create(#self.StatModifiers[index])
    local funcs = table.create(#self.StatModifiers[index])

	for _, modifier in ipairs(self.StatModifiers[index]) do
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
        value = func(value)
    end

	return value
end

function Properties:CreateStat(index)
	self.StatModifiers[index] = {
        -- StatModifier.new()
    }
end

function Properties:GetAllStats()
	local statArr = {}
	for stat in pairs(self.StatModifiers) do
		table.insert(statArr, stat)
	end
	return statArr
end

function Properties:SetValue(index, value)
	local oldValue = self[index]
	self[index] = value
	self.PropertyChanged:Fire(index, value, oldValue)
end

return Properties