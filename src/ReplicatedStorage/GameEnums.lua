local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnumsClass = require(ReplicatedStorage.Modules.General.EnumsClass)

local GameEnums = {
    ToolStates = {
        Idle = {},
        Equipping = {},
    },

    GunStates = {
        Idle = {},
        Shooting = {},
        Reloading = {},
    }
}

return EnumsClass.new(GameEnums, "GameEnums")