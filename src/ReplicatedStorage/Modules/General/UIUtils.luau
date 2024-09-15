--!native
--!strict

local UIUtils = {}

function UIUtils.mulUDim2(u1: UDim2, u2: UDim2)
    return UDim2.new(u1.X.Scale * u2.X.Scale, u1.X.Offset * u2.X.Offset, u1.Y.Scale * u2.Y.Scale, u1.Y.Offset * u2.Y.Offset)
end

function UIUtils.divUDim2(u1: UDim2, u2: UDim2)
    return UDim2.new(u1.X.Scale / u2.X.Scale, u1.X.Offset / u2.X.Offset, u1.Y.Scale / u2.Y.Scale, u1.Y.Offset / u2.Y.Offset)
end

return UIUtils