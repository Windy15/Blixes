local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)
local RemotesInventory = ReplicatedStorage.Remotes.PlayerData.Inventory

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(capacity)
    local new = setmetatable({
        SlotEquipped = nil,
        Tools = {},
        Keybinds = {},
        Capacity = capacity or 0,

        OnToolAdded = Signal.new(),
        OnToolRemoved = Signal.new(),
        OnEquipped = Signal.new(),
        OnUnequipped = Signal.new()
    }, Inventory)

    return new
end

return Inventory