--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local ToolClass = require(ReplicatedStorage.Tools.Classes.ToolClass)

type InventoryImpl = {
    __index: InventoryImpl,

    new: (capacity: number) -> Inventory,
    EquipTool: (self: Inventory, tool: ToolClass.ToolObject) -> (),
    UnequipCurrent: (self: Inventory) -> boolean,
}

export type Inventory = typeof(setmetatable({} :: {
    SlotEquipped: ToolClass.ToolObject?,
    Tools: {ToolClass.ToolObject},
    Capacity: number,

    OnToolAdded: Signal.Signal<ToolClass.ToolObject>,
    OnToolRemoved: Signal.Signal<ToolClass.ToolObject>,
    OnEquipped: Signal.Signal<ToolClass.ToolObject>,
    OnUnequipped: Signal.Signal<ToolClass.ToolObject>,
}, {} :: InventoryImpl))

local Inventory = {} :: InventoryImpl
Inventory.__index = Inventory

function Inventory.new(capacity)
    local self = setmetatable({
        SlotEquipped = nil,
        Tools = {},
        Capacity = capacity,

        OnToolAdded = Signal.new(),
        OnToolRemoved = Signal.new(),
        OnEquipped = Signal.new(),
        OnUnequipped = Signal.new()
    }, Inventory)

    return self
end

function Inventory:EquipTool(tool)
    self:UnequipCurrent()
    self.SlotEquipped = tool
    self.OnEquipped:Fire(tool)
end

function Inventory:UnequipCurrent()
    local current = self.SlotEquipped
    if current then
        current:Equip()
        self.SlotEquipped = nil
        self.OnUnequipped:Fire(current)
        return true
    end
    return false
end

return Inventory