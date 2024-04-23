local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(tools, capacity)
    local new = setmetatable({
        Tools = tools or {},
        Capacity = capacity or 0,

        ToolAdded = Signal.new(),
        ToolRemoved = Signal.new()
    }, Inventory)

    return new
end

function Inventory:InsertTool(item, index)
    table.insert(self.Items, item, index or 1)
    self.ToolAdded:Fire(item)
end

function Inventory:RemoveTool(remove)
    if type(remove) == "number" then
        local item = self.Items[remove]
        table.remove(self.Items, remove)
        self.ToolRemoved:Fire(item, remove)
    else
        local index = table.find(self.Items, remove)
        assert(index, "Could not find "..StringUtils.formatAddress(remove, "Item").." in "..StringUtils.formatAddress(self, "Inventory"))
        self.ToolRemoved:Fire(remove, index)
    end
end

function Inventory:ClearTools()
    for index, item in ipairs(self.Items) do
        self.Items[index] = nil
        self.ToolRemoved:Fire(item, index)
    end
end

return Inventory