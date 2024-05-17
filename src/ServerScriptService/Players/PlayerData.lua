local ReplicatedStorage = game:GetService("ReplicatedStorage")

local List = require(ReplicatedStorage.Modules.General.ListClass)

local DataMeta = {}
local PlayerData = List.new({}, DataMeta)

return PlayerData