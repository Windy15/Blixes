--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
require(script.StatModifier)

local StatHolder = {}
StatHolder.__name = StatHolder

function StatHolder.new(new)
	new = setmetatable(new or {}, StatHolder)
	new.StatChanged = Signal.new()
	new.StatModifiers = {}
	return new
end

local function checkStat(self, name)
	if not self.StatModifiers[name] then
		error("name '"..name.."' is not a stat for this table", 3)
	end
end

function StatHolder:GetStat(name)
	local value = self[name]
	if not value then return nil end
	checkStat(self, name)

    local adders = table.create(#self.StatModifiers[name])
    local funcs = table.create(#self.StatModifiers[name])

	for _, modifier in ipairs(self.StatModifiers[name]) do
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

function StatHolder:CreateStat(name)
	self.StatModifiers[name] = {
        -- StatModifier.new()
    }
end

function StatHolder:GetAllStats(): {{Name: string, BaseValue: any, Value: any}}
	local statArr = {}
	for stat, value in pairs(self.StatModifiers) do
		table.insert(statArr, {
			Name = stat,
			BaseValue = value,
			Value = self:GetStat(stat)
		})
	end
	return statArr
end

function StatHolder:SetValue(name, value)
	checkStat(self, name)
	local oldValue = self[name]
	self[name] = value
	self.StatChanged:Fire(name, value, oldValue)
end

function StatHolder:AddModifier(name, modifier)
    checkStat(self, name)
    table.insert(self.StatModifiers[name], modifier)
end

function StatHolder:RemoveModifier(name, modifier)
    checkStat(self, name)
	local i = table.find(self.StatModifiers, modifier)
	if i then
		table.remove(self.StatModifiers[name], i)
	end
end

local function derivesFrom(val, class)
	local meta = getmetatable(val)
	repeat
		if meta == class then
			return true
		end
		meta = getmetatable(meta)
	until not meta or meta == val
	return false
end

function StatHolder:Destroy()
	for _, val in ipairs(self) do
		if type(val) == "table" and derivesFrom(val, Signal) then
			val:Destroy()
		end
	end
end

return StatHolder