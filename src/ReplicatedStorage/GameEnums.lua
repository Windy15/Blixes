local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnumList = require(ReplicatedStorage.Modules.General.EnumList)

local GameEnums = {
    ToolState = {
        Idle = 1,
        Equipping = 2,
    },

    GunState = {
        Idle = 1,
        Shooting = 2,
        Reloading = 3,
    },

    GunMode = {
        Semi = 1,
        Auto = 2,
        Burst = 3,
        Special = 4
    }
}

EnumList.new(GameEnums, "GameEnums")

return GameEnums :: typeof(GameEnums) | EnumList.EnumList