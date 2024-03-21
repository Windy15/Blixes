--[[
		Create a new RaycastHitbox Object with "RaycastHitbox.new(model: Instance?, rayParams: RaycastParams?, rayPointName: string?)"
			- "model" is the Instance which the RayPoint attachments reside in
			- "rayParams" are the RaycastParams for the RayPoints
			- "rayPointName" is the name of rayPoints which you want to include in the hitbox, otherwise all attachments with a 
			"RayPointType" attribute will be included
		
		RayPoints can have the following Attributes:
			"RayEnabled": bool - Determines if this raypoint is enabled or not (if it is nil then it will be set to true)
			
			"RayPointType": string - The type of raycasting the point should do:
				"Line" - workspace:Raycast()
				"Sphere" - workspace:Spherecast()
				"Block" - workspace:BlockCast()
			
			"RaySize": number | vector3 - The size of the raycast (only applies to certain RayPointTypes)
				if "RayPointType" is set to "Sphere" then it will be a number which is radius of the SphereCast
				if "RayPointType" is set to "Block" then it will be a Vector3 which is the size of the BlockCast
			
			"RayOrientation": vector3 - The orientation of the BlockCast (only applies if "RayPointType" is "Block" )
]]