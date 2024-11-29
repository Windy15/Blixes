local Types = require(script.Parent.Parent.TypeHolder)

@native
local function HitCalc(projData: Types.ProjData)
	local result = workspace:Spherecast(projData.Position, projData.Radius, projData.Position - projData.LastPosition, projData.RayParams)
	return result
end

return HitCalc