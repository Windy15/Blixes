local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local RemotesInventory = ReplicatedStorage.Remotes.PlayerData.Inventory

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(capacity, tools)
    local new = setmetatable({
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

function Inventory:AddTool(tool, slotIndex: number?)
    if slotIndex then
        table.insert(self.Tools, slotIndex, tool)
    else
        table.insert(self.Tools, tool)
    end
    self.OnToolAdded:Fire(tool)
end

function Inventory:RemoveTool(slotIndex: number)
    local tool = self.Tools[slotIndex]
    table.remove(self.Tools, slotIndex)
    self.ToolRemoved:Fire(tool, slotIndex)
end

function Inventory:MoveSlot(slotIndex: number, newSlotIndex: number)
    local tool = table.find(self.Tools[slotIndex])
    if tool then
        table.remove(self.Tools, slotIndex)
        table.insert(self.Tools, newSlotIndex, tool)
        RemotesInventory.SlotMoved:FireServer(slotIndex, newSlotIndex)
    end
end

function Inventory:ClearTools()
    for slotIndex in ipairs(self.Tools) do
        self:RemoveTool(slotIndex)
    end
end

function Inventory:GetEquipped()
    return self.SlotEquipped and self.Tools[self.SlotEquipped] or nil
end

function Inventory:EquipSlot(slotIndex: number)
    self.SlotEquipped = slotIndex
    local tool = self:GetEquipped()
    if tool then
        self.OnEquipped:Fire(tool, slotIndex)
    end
    return tool
end

function Inventory:UnequipSlot()
    if self.SlotEquipped then
        self.SlotEquipped:Unequip()
        self.OnUnequipped:Fire(self:GetTool(), self.SlotEquipped)
        self.SlotEquipped = nil
    end
end

return Inventory