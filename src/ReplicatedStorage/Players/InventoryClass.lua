local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(items, capacity)
    local new = setmetatable({
        Items = items or {},
        Capacity = capacity or 0,

        ItemAdded = Signal.new(),
        ItemRemoved = Signal.new()
    }, Inventory)

    return new
end

function Inventory:InsertItem(item, index)
    table.insert(self.Items, item, index or 1)
    self.ItemAdded:Fire(item)
end

function Inventory:RemoveItem(remove)
    if type(remove) == "number" then
        local item = self.Items[remove]
        table.remove(self.Items, remove)
        self.ItemRemoved:Fire(item, remove)
    else
        local index = table.find(self.Items, remove)
        assert(index, "Could not find "..StringUtils.formatAddress(remove, "Item").." in "..StringUtils.formatAddress(self, "Inventory"))
        self.ItemRemoved:Fire(remove, index)
    end
end

function Inventory:Clear()
    for index, item in ipairs(self.Items) do
        self.Items[index] = nil
        self.ItemRemoved:Fire(item, index)
    end
end

return Inventory