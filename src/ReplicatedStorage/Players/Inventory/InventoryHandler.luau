--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mouse = Players.LocalPlayer:GetMouse()

local ClientData = require(ReplicatedStorage.Players.PlayerData)[Players.LocalPlayer]
local ToolClass = require(ReplicatedStorage.Tools.Classes.ToolClass)

local inventory = ClientData.Inventory

local RemotesInventory = ReplicatedStorage.Remotes.PlayerData.Inventory

local InventoryHandler = {
    Actions = {
        EQUIP = "Equip",
        UNEQUIP = "Unequip",
    }
}

local SlotKeys: {EnumItem} = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five,
    Enum.KeyCode.Six,
    Enum.KeyCode.Seven,
    Enum.KeyCode.Eight,
    Enum.KeyCode.Nine,
    Enum.KeyCode.Zero,
}

-- Index of keycode in 'SlotKeys' points to tool
--[[
    BindedTools = {[1] = Tool}
    SlotKeys = {[1] = Enum.KeyCode.One}
    Enum.Keycode.One -> Tool

    BindedTools will have nil values, use #SlotKeys instead
]]
local BindedTools: {[number]: ToolClass.ToolObject} = table.create(#SlotKeys)

local function equipToolOnInput(_, inputState: EnumItem, inputObject: InputObject)
    if inputState == Enum.UserInputState.Begin then
        local bindIndex = table.find(SlotKeys, inputObject.KeyCode)
        if bindIndex then
            local tool = BindedTools[bindIndex]
            if tool then
                inventory:EquipTool(tool)
            end
        end
    end
end

local function getBindedIndex(tool: ToolClass.ToolObject): number?
    for i, binded in BindedTools do
        if binded == tool then
            return i
        end
    end
    return nil
end

ContextActionService:BindAction(InventoryHandler.Actions.EQUIP, equipToolOnInput, false, table.unpack(SlotKeys))

Mouse.WheelForward:Connect(function()
    local index = getBindedIndex(inventory.SlotEquipped)
    if index then
        -- Go from the current tool to the first tool
        for i = index - 1, 1, -1 do
            if BindedTools[i] then
                inventory:EquipTool(BindedTools[i])
                return
            end
        end
        -- Wrap around to the last tool until the current tool
        for i = #SlotKeys, index + 1 do
            if BindedTools[i] then
                inventory:EquipTool(BindedTools[i])
                return
            end
        end
    end
end)

Mouse.WheelBackward:Connect(function()
    local index = getBindedIndex(inventory.SlotEquipped)
    if index then
        -- Go from the current tool to the last tool
        for i = index + 1, #SlotKeys do
            if BindedTools[i] then
                inventory:EquipTool(BindedTools[i])
                return
            end
        end
        -- Wrap around to the first tool until the current tool
        for i = 1, index - 1 do
            if BindedTools[i] then
                inventory:EquipTool(BindedTools[i])
                return
            end
        end
    end
end)

RemotesInventory.InventoryCreated.OnClientEvent:Connect(function(capacity: number)
    inventory.Capacity = capacity
end)

RemotesInventory.ToolAdded.OnClientEvent:Connect(function(tool, slotIndex: number)
    inventory[slotIndex] = tool

    for i in ipairs(SlotKeys) do
        if not BindedTools[i] then
            BindedTools[i] = tool
        end
    end

    inventory.OnToolAdded:Fire(tool)
end)

RemotesInventory.ToolRemoved.OnClientEvent:Connect(function(slotIndex: number)
    local tool = inventory[slotIndex]

    local index = getBindedIndex(tool)
    if index then
        BindedTools[index] = nil
    end

    if inventory.SlotEquipped == tool then
        inventory.SlotEquipped = nil
    end

    inventory.Tools[slotIndex] = nil

    inventory.OnToolRemoved:Fire(tool)
end)

return InventoryHandler