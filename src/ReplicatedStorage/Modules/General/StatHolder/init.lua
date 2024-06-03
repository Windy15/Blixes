--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
require(script.StatModifier)

local StatHolder = {}
StatHolder.__index = StatHolder

function StatHolder.new(new)
	new = setmetatable(new or {}, StatHolder)
	new.StatChanged = Signal.new()
	new.StatModifiers = {}
	return new
end

function StatHolder:GetStat(index)
	local value = self[index]
	if not value then return nil end
	if not self.StatModifiers[index] then
		error("Index '"..index.."' is not a stat for this table", 2)
	end

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
        value = func(self, value)
    end

	return value
end

function StatHolder:CreateStat(index)
	self.StatModifiers[index] = {
        -- StatModifier.new()
    }
end

function StatHolder:GetAllStats(): {{Name: string, BaseValue: any, Value: any}}
	local statArr = {}
	for stat in pairs(self.StatModifiers) do
		table.insert(statArr, {
			Name = stat,
			BaseValue = self[stat],
			Value = self:GetStat(stat)
		})
	end
	return statArr
end

function StatHolder:SetValue(index, value)
	local oldValue = self[index]
	self[index] = value
	self.StatChanged:Fire(index, value, oldValue)
end

return StatHolder