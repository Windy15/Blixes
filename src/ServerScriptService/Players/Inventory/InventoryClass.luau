local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local StringUtils = require(ReplicatedStorage.Modules.General.StringUtils)
local RemotesInventory = ReplicatedStorage.Remotes.PlayerData.Inventory

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(player, capacity, tools)
    local new = setmetatable({
        Player = player,

        SlotEquipped = nil,
        Tools = tools or table.create(capacity),
        Capacity = capacity or 0,

        OnToolAdded = Signal.new(),
        OnToolRemoved = Signal.new(),
        OnEquipped = Signal.new(),
        OnUnequipped = Signal.new()
    }, Inventory)

    return new
end

function Inventory:AddTool(tool, slotIndex: number?)
    if #self.Tools >= self.Capacity then return end
    if not tool.Instance then
        error(string.format("Inserted %s has no instance", StringUtils.formatAddress(tool, "Tool")), 2)
    end

    tool.Instance.Destroying:Connect(function()
        self:RemoveTool(tool)
    end)

    tool.Instance.Parent = self.Player.Backpack
    table.insert(self.Tools, tool, slotIndex)
    self.OnToolAdded:Fire(tool, slotIndex)
    RemotesInventory.ToolAdded:FireClient(self.Player, tool, slotIndex)
end

function Inventory:RemoveTool(slotIndex: number)
    local tool = self.Tools[slotIndex]
    table.remove(self.Tools, slotIndex)
    if self.Player and tool.Instance and tool.Instance.Parent == self.Player.Backpack then
        tool.Parent = nil
    end
    self.ToolRemoved:Fire(tool, slotIndex)
    RemotesInventory.ToolRemoved:FireClient(self.Player, slotIndex)
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
    local tool = self.Tools[slotIndex]
    if tool then
        self.SlotEquipped = slotIndex
        self.SlotEquipped:Equip()
        self.OnEquipped:Fire(tool)
        RemotesInventory.ToolEquipped:FireClient(self.Player, slotIndex)
    end
end

function Inventory:UnequipSlot()
    if self.SlotEquipped then
        self.SlotEquipped:Unequip()
        self.SlotEquipped.Instance.Parent = self.Player.Backpack
        self.OnUnequipped:Fire(self.SlotEquipped)
        self.SlotEquipped = nil
        RemotesInventory.ToolUnequipped:FireClient(self.Player)
    end
end

return Inventory