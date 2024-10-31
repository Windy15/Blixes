local Types = require(script.Parent.Parent.TypeHolder)

@native
local function HitCalc(projData: Types.ProjData)
	local result = workspace:Raycast(projData.Position, projData.LastPosition - projData.Position, projData.RayParams)
	return result
end

return HitCalc