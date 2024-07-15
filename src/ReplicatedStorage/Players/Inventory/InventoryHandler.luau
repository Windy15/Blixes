local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientData = require(ReplicatedStorage.Players.PlayerData)[Players.LocalPlayer]
local InventoryClass = require(ReplicatedStorage.Players.Inventory.InventoryClass)
local ToolClass = require(ReplicatedStorage.ToolClasses.ToolClass)

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

local BindedTools: {[number]: ToolClass.ToolObject} = {}

local function equipTool(_, inputState: EnumItem, inputObject: InputObject)
    local inventory = ClientData.Inventory
    if not inventory then return end

    if inputState == Enum.UserInputState.Begin then
        local bindIndex = table.find(SlotKeys, inputObject.KeyCode)
        if bindIndex then
            local tool = BindedTools[bindIndex]
            if tool then
                tool:Equip()
            end
        end
    end
end

RemotesInventory.InventoryCreated.OnClientEvent:Connect(function(capacity: number)
    ContextActionService:UnbindAction(InventoryHandler.Actions.EQUIP)
    ClientData.Inventory = InventoryClass.new(capacity)
    ContextActionService:BindAction(InventoryHandler.Actions.EQUIP, equipTool, false, table.unpack(SlotKeys))
end)

RemotesInventory.ToolAdded.OnClientEvent:Connect(function(tool, slotIndex: number)
    ClientData.Inventory[slotIndex] = tool

    for i in ipairs(SlotKeys) do
        if not BindedTools[i] then
            BindedTools[i] = tool
        end
    end
end)

RemotesInventory.ToolRemoved.OnClientEvent:Connect(function(slotIndex: number)
    local tool = ClientData.Inventory[slotIndex]

    for i, bindedTool in ipairs(BindedTools) do
        if bindedTool == tool then
            BindedTools[i] = nil
        end
    end

    ClientData.Inventory[slotIndex] = nil
end)

return InventoryHandler