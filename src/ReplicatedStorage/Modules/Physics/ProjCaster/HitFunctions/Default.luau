local Types = require(script.Parent.Parent.TypeHolder)

@native
local function HitCalc(projData: Types.ProjData)
	local rayDir = projData.Position - projData.LastPosition
	rayDir += rayDir.Unit * projData.Radius
	local result = workspace:Raycast(projData.Position, rayDir, projData.RayParams)
	return result
end

return HitCalc