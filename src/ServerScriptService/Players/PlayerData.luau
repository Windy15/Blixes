local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.General.Signal)

local DataMeta = {
    PlayerLoaded = Signal.new()
}
DataMeta.__index = DataMeta
DataMeta.__mode = "k"
local PlayerData = setmetatable({}, DataMeta)

return PlayerData