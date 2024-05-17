local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService.Players.PlayerData)
local RemotesInventory = ReplicatedStorage.Remotes.PlayerData.Inventory

local InventoryHandler = {}

RemotesInventory.SlotMoved.OnServerEvent:Connect(function(player: Player, slotIndex: number, newSlotIndex: number)
    local inventory = PlayerData[player].Inventory
    if inventory then
        inventory:MoveSlot(slotIndex, newSlotIndex)
    else
        error("Player "..player.Name.." has no Inventory")
    end
end)

return InventoryHandler