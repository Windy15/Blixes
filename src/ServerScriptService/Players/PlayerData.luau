local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataMeta = {}
DataMeta.__index = DataMeta
local PlayerData = setmetatable({}, DataMeta)

return PlayerData