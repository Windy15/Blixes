local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnumsClass = require(ReplicatedStorage.Modules.General.EnumsClass)

local GameEnums = {
    ToolState = {
        Idle = {},
        Equipping = {},
    },

    GunState = {
        Idle = {},
        Shooting = {},
        Reloading = {},
    },

    GunMode = {
        Semi = {},
        Auto = {},
        Burst = {},
        Special = {}
    }
}

return EnumsClass.new(GameEnums, "GameEnums")