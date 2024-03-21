local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.GoodSignal)

local Properties = {}

Properties.__index = Properties

function Properties.new(new)
	new = new or {}
	
	new.PropertyChanged = Signal.new()
	new.Modifiers = {
		Multipliers = {},
		Adders = {}
	}
	
	return new
end

function Properties:GetModified(index)
	local value = self[index]
	
	if not value then return nil end
	
	local modifiers = self.Modifiers
	
	local multipliers = modifiers.Multipliers[index]
	
	if multipliers then
		for _, mult in pairs(multipliers) do
			value *= mult
		end
	end
	
	local adders = modifiers.Adders[index]
	
	if adders then
		for _, add in pairs(adders) do
			value += add
		end
	end
	
	return value
end

function Properties:SetValue(index, value)
	self[index] = value
	self.Signals.Changed:Fire(index, value)
end

return Properties