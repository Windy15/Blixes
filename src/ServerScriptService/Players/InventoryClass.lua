local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(player, tools, capacity)
    local new = setmetatable({
        Player = player,

        SlotEquipped = nil,
        Tools = tools or {},
        Capacity = capacity or 0,

        OnToolAdded = Signal.new(),
        OnToolRemoved = Signal.new(),
        OnEquipped = Signal.new(),
        OnUnequipped = Signal.new()
    }, Inventory)

    return new
end

function Inventory:InsertTool(tool, index)
    assert(tool.Instance, "Inserted tool has no instance")
    tool.Instance.Destroying:Connect(function()
        self:RemoveTool(tool)
    end)
    tool.Instance.Parent = self.Player.Backpack
    table.insert(self.Tools, tool, index)
    self.OnToolAdded:Fire(tool, index)
end

function Inventory:RemoveTool(remove)
    if type(remove) == "number" then
        local tool = self.Tools[remove]
        table.remove(self.Tools, remove)
        if self.Player and tool.Instance and tool.Instance.Parent == self.Player.Backpack then
            tool.Parent = nil
        end
        self.ToolRemoved:Fire(tool, remove)
    else
        local index = table.find(self.Tools, remove)
        assert(index, "Could not find "..StringUtils.formatAddress(remove, "Tool").." in "..StringUtils.formatAddress(self, "Inventory"))
        self.OnToolRemoved:Fire(remove, index)
    end
end

function Inventory:ClearTools()
    for index in ipairs(self.Tools) do
        self:RemoveTool(index)
    end
end

function Inventory:SetEquipped(tool)
    local oldEquipped = self.SlotEquipped
    self.SlotEquipped = tool
    if tool and tool ~= oldEquipped then
        self.OnEquipped:Fire(tool)
    elseif not tool and oldEquipped ~= nil then
        self.OnUnequipped:Fire(oldEquipped)
    end
end

return Inventory