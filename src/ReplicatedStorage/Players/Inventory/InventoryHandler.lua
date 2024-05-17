local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientData = require(ReplicatedStorage.Players.PlayerData)[Players.LocalPlayer]
local InventoryClass = require(ReplicatedStorage.Players.Inventory.InventoryClass)
local RemotesInventory = ReplicatedStorage.Remotes.PlayerData.Inventory

local InventoryHandler = {
    Actions = {
        EQUIP = "Equip",
        UNEQUIP = "Unequip"
    }
}

local KeyCode_SlotIndex: {EnumItem} = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five,
    Enum.KeyCode.Six,
    Enum.KeyCode.Seven,
    Enum.KeyCode.Eight,
    Enum.KeyCode.Nine,
    Enum.KeyCode.Zero
}

local function equipTool(_, inputState: EnumItem, inputObject: InputObject)
    local inventory = ClientData.Inventory
    if not inventory then return end

    if inputState == Enum.UserInputState.Begin then
        local slotIndex = table.find(KeyCode_SlotIndex, inputObject.KeyCode)
        local tool = inventory.Tools[slotIndex]
        if tool then
            tool:Equip()
        end
    end
end

RemotesInventory.InventoryCreated.OnClientEvent:Connect(function(capacity: number)
    ContextActionService:UnbindAction(InventoryHandler.Actions.EQUIP)
    ClientData.Inventory = InventoryClass.new(capacity)
    ContextActionService:BindAction(InventoryHandler.Actions.EQUIP, equipTool, false, table.unpack(KeyCode_SlotIndex))
end)

RemotesInventory.ToolAdded.OnClientEvent:Connect(function(tool, slotIndex: number)
    ClientData.Inventory:AddTool(tool, slotIndex)
end)

RemotesInventory.ToolRemoved.OnClientEvent:Connect(function(slotIndex: number)
    ClientData.Inventory:RemoveTool(slotIndex)
end)

return InventoryHandler